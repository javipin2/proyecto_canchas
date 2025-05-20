const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.assignEncargadoRole = functions.https.onCall(async (data, context) => {
  // Verifica que el que llama sea un admin
  if (!context.auth || context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Solo los administradores pueden asignar roles."
    );
  }

  const { userId } = data;

  if (!userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Se requiere el ID del usuario."
    );
  }

  try {
    await admin.auth().setCustomUserClaims(userId, { role: "encargado" });
    return { message: `Rol de encargado asignado al usuario ${userId}` };
  } catch (error) {
    throw new functions.https.HttpsError(
      "internal",
      `Error al asignar el rol: ${error.message}`
    );
  }
});