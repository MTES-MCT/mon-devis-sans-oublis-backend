# RNT (Référentiel National des Travaux)

## Pour mettre à jour
1. Déposez le nouveau schéma XSD dans `lib/rnt/schemas/`
2. Mettez à jour `Rnt::Schema::SCHEMA_VERSION` en conséquence et aussi `Rnt::Schema::VERSION`
3. Générez le schéma au format JSON
  - `export RNT_SCHEMA_VERSION=0.1.0`
  - `cp mdd_v$RNT_SCHEMA_VERSION.xsd schema.xsd`
  - `rails runner xsd_to_openapi.rb`
  - `cp schema_openapi.json lib/rnt/schemas/mdd_v$RNT_SCHEMA_VERSION.json`
4. Testez
5. Commitez et déployez

### Variables d'environnement principales

| Variable                       | Description                           | Exemple                                                  | Requis    |
| ------------------------------ | ------------------------------------- | -------------------------------------------------------- | --------- |
| `RNT_SKIP_SSL_VERIFICATION`                     | Ne pas vérifier la connexion SSL avec le Web Service RNT             | `false`                            | Optionnel    |
