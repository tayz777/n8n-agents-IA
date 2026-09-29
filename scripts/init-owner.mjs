const baseUrl = process.env.N8N_INTERNAL_URL ?? 'http://127.0.0.1:5678';

const owner = {
  email: process.env.N8N_OWNER_EMAIL,
  firstName: process.env.N8N_OWNER_FIRST_NAME,
  lastName: process.env.N8N_OWNER_LAST_NAME,
  password: process.env.N8N_OWNER_PASSWORD,
};

for (const [name, value] of Object.entries(owner)) {
  if (!value) {
    throw new Error(`La variable ${name} du compte propriétaire est manquante.`);
  }
}

async function waitForSettings() {
  let lastError = new Error('n8n ne répond pas encore.');

  for (let attempt = 1; attempt <= 90; attempt += 1) {
    try {
      const response = await fetch(`${baseUrl}/rest/settings`);
      const responseBody = await response.text();

      if (!response.ok) {
        throw new Error(`Réponse HTTP ${response.status}.`);
      }

      const payload = JSON.parse(responseBody);
      if (payload?.data?.settings?.userManagement || payload?.data?.userManagement) {
        return payload;
      }

      throw new Error('La configuration n8n est encore incomplète.');
    } catch (error) {
      lastError = error;
      if (attempt < 90) {
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
    }
  }

  throw new Error(`n8n n'est pas prêt après 90 secondes : ${lastError.message}`);
}

const settingsPayload = await waitForSettings();
const needsOwner =
  settingsPayload?.data?.settings?.userManagement?.showSetupOnFirstLoad ??
  settingsPayload?.data?.userManagement?.showSetupOnFirstLoad;

if (needsOwner === false) {
  console.log('Le compte propriétaire n8n existe déjà. Initialisation ignorée.');
  process.exit(0);
}

const setupResponse = await fetch(`${baseUrl}/rest/owner/setup`, {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(owner),
});

if (!setupResponse.ok) {
  const details = await setupResponse.text();
  throw new Error(
    `Création du compte propriétaire impossible (${setupResponse.status}) : ${details}`,
  );
}

console.log(`Compte propriétaire n8n créé pour ${owner.email}.`);
