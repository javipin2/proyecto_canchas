const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Webhook para recibir notificaciones de Wompi
exports.wompiWebhook = functions.https.onRequest(async (req, res) => {
  try {
    console.log('Webhook recibido:', JSON.stringify(req.body, null, 2));
    
    const event = req.body;
    
    // Verificar que es el evento correcto
    if (event.event === 'transaction.updated') {
      const transaction = event.data.transaction;
      const reference = transaction.reference;
      const status = transaction.status;
      
      console.log(`Procesando transacción ${reference} con estado ${status}`);
      
      if (status === 'APPROVED') {
        // Actualizar documento temporal inmediatamente
        await admin.firestore()
          .collection('reservas_temporales')
          .doc(reference)
          .update({
            estado: 'pagado',
            transaction_id: transaction.id,
            payment_method: transaction.payment_method?.type,
            amount_paid: transaction.amount_in_cents / 100,
            processed_at: admin.firestore.FieldValue.serverTimestamp(),
            webhook_received: true,
            webhook_data: {
              status: status,
              payment_method: transaction.payment_method,
              finalized_at: transaction.finalized_at
            }
          });
          
        console.log(`Pago aprobado para referencia ${reference}`);
        
      } else if (status === 'DECLINED') {
        await admin.firestore()
          .collection('reservas_temporales')
          .doc(reference)
          .update({
            estado: 'rechazado',
            webhook_received: true,
            decline_reason: transaction.status_message,
            processed_at: admin.firestore.FieldValue.serverTimestamp()
          });
          
        console.log(`Pago rechazado para referencia ${reference}`);
        
      } else if (status === 'VOIDED') {
        await admin.firestore()
          .collection('reservas_temporales')
          .doc(reference)
          .update({
            estado: 'cancelado',
            webhook_received: true,
            processed_at: admin.firestore.FieldValue.serverTimestamp()
          });
          
        console.log(`Pago cancelado para referencia ${reference}`);
      }
    }
    
    res.status(200).send('OK');
    
  } catch (error) {
    console.error('Error en webhook:', error);
    res.status(500).send('Error processing webhook');
  }
});

// Función para limpiar documentos temporales expirados
exports.cleanupExpiredReservations = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  try {
    const db = admin.firestore();
    const now = Date.now();
    const fiveMinutesAgo = now - (5 * 60 * 1000);
    
    // Buscar documentos temporales expirados
    const expiredDocs = await db.collection('reservas_temporales')
      .where('expira_en', '<', fiveMinutesAgo)
      .where('estado', 'in', ['bloqueado', 'pendiente'])
      .get();
    
    const batch = db.batch();
    let count = 0;
    
    expiredDocs.forEach((doc) => {
      batch.update(doc.ref, {
        estado: 'expirado',
        expired_at: admin.firestore.FieldValue.serverTimestamp()
      });
      count++;
    });
    
    if (count > 0) {
      await batch.commit();
      console.log(`Limpiados ${count} documentos temporales expirados`);
    }
    
    return null;
  } catch (error) {
    console.error('Error en limpieza automática:', error);
    return null;
  }
});

// Función para procesar reservas pagadas automáticamente
exports.processApprovedPayments = functions.firestore
  .document('reservas_temporales/{docId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      
      // Solo procesar si cambió a estado 'pagado' y hay webhook confirmado
      if (before.estado !== 'pagado' && 
          after.estado === 'pagado' && 
          after.webhook_received === true &&
          !after.processed_to_final) {
        
        const docId = context.params.docId;
        console.log(`Procesando pago aprobado para ${docId}`);
        
        // Crear la reserva final
        const reservaFinal = {
          cancha: {
            nombre: after.cancha,
            // Agregar otros campos de cancha si es necesario
          },
          fecha: after.fecha,
          horario: {
            horaFormateada: after.horario
          },
          nombre: after.datos_cliente.nombre,
          telefono: after.datos_cliente.telefono,
          email: after.datos_cliente.email,
          montoPagado: after.monto,
          montoTotal: after.monto, // Si es abono parcial, ajustar aquí
          tipoAbono: after.monto >= (after.precio_total || after.monto) ? 'completo' : 'parcial',
          confirmada: true,
          fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
          transactionId: after.transaction_id,
          paymentMethod: after.payment_method,
          reference: docId
        };
        
        const db = admin.firestore();
        
        // Usar transacción para asegurar consistencia
        await db.runTransaction(async (transaction) => {
          // 1. Guardar reserva final
          const reservaRef = db.collection('reservas').doc();
          transaction.set(reservaRef, reservaFinal);
          
          // 2. Marcar documento temporal como procesado
          const tempRef = db.collection('reservas_temporales').doc(docId);
          transaction.update(tempRef, {
            processed_to_final: true,
            final_reservation_id: reservaRef.id,
            final_processed_at: admin.firestore.FieldValue.serverTimestamp()
          });
          
          // 3. Cancelar otros intentos para la misma reserva
          const reservaKey = after.reserva_key;
          if (reservaKey) {
            const otherAttempts = await db.collection('reservas_temporales')
              .where('reserva_key', '==', reservaKey)
              .where('estado', 'in', ['bloqueado', 'pendiente'])
              .get();
            
            otherAttempts.forEach((doc) => {
              if (doc.id !== docId) {
                transaction.update(doc.ref, {
                  estado: 'cancelado_por_otro_pago',
                  cancelado_en: admin.firestore.FieldValue.serverTimestamp(),
                  motivo_cancelacion: 'Otro usuario completó el pago primero'
                });
              }
            });
          }
        });
        
        console.log(`Reserva final creada exitosamente para ${docId}`);
      }
      
    } catch (error) {
      console.error('Error procesando pago aprobado:', error);
    }
  });