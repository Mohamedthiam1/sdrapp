const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();

exports.updateRuches = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Europe/Paris",
  },
  async () => {
    const ruchesRef = db.collection("ruches");
    const snapshot = await ruchesRef.get();

    const updates = [];

    snapshot.forEach((doc) => {
      const data = doc.data();

      const inCount = Math.max(0, (data.in || 0) + getRandomInt(-5, 10));
      const outCount = Math.max(0, (data.out || 0) + getRandomInt(-5, 10));
      const total = inCount + outCount;
      const temperature = Math.min(50, Math.max(0, (data.temperature || 20) + getRandomFloat(-2.25, 2.25)));
      const spectrum = Array.from({ length: getRandomInt(3, 6) }, () =>
        parseFloat((Math.random() * 2.25).toFixed(2))
      );

      const alertReasons = getAlertReasons({ in: inCount, out: outCount, total, temperature, spectrum });
      const alert = alertReasons.length > 0;

      updates.push(
        ruchesRef.doc(doc.id).update({
          in: inCount,
          out: outCount,
          total,
          temperature,
          spectrum,
          alert,
          alertReasons,
        })
      );
    });

    await Promise.all(updates);
    logger.info("✅ Toutes les ruches ont été mises à jour avec alertes.");
  }
);

function getAlertReasons(hive) {
  const reasons = [];

  const temperature = typeof hive.temperature === "number" ? hive.temperature : 0;
  const inCount = hive.in || 0;
  const outCount = hive.out || 0;
  const total = inCount + outCount;
  const spectrum = Array.isArray(hive.spectrum) ? hive.spectrum : [];

  if (temperature < 10) {
    reasons.push("Température trop basse (moins de 10°C)");
  } else if (temperature > 40) {
    reasons.push("Température trop élevée (plus de 40°C)");
  }

  if (total === 0) {
    reasons.push("Aucune activité détectée (entrée/sortie/total à 0)");
  } else {
    if (outCount >= total * 0.9) {
      reasons.push("La plupart des abeilles sont sorties — possible perturbation externe");
    }
    if (outCount === 0 && inCount > 0) {
      reasons.push("Aucune sortie détectée alors qu'il y a des entrées");
    }
  }

  if (spectrum.length > 0) {
    const maxVal = Math.max(...spectrum);
    const avgVal = spectrum.reduce((a, b) => a + b, 0) / spectrum.length;

    if (maxVal > 0.9) {
      reasons.push("Pics sonores élevés détectés dans le spectre");
    } else if (avgVal < 0.05) {
      reasons.push("Activité sonore très faible, possible silence anormal");
    }
  } else {
    reasons.push("Données de spectre sonore manquantes");
  }

  return reasons;
}

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function getRandomFloat(min, max) {
  return Math.random() * (max - min) + min;
}
