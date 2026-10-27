# Deploying to SAP BTP Cloud Foundry from the command prompt (feature/postgresql)

This branch deploys the three database-backed services — `customers-service`, `vets-service`
and `visits-service` — as separate Cloud Foundry apps sharing one SAP BTP PostgreSQL instance.
Config Server, Eureka, API Gateway, Admin Server and GenAI service are **not** deployed.

## What changed on this branch

| File | Change |
|---|---|
| `spring-petclinic-{customers,vets,visits}-service/pom.xml` | Added `org.postgresql:postgresql` (runtime) |
| `.../src/main/resources/db/postgresql/{schema,data}.sql` | PostgreSQL versions of the MySQL scripts |
| `.../src/main/resources/application.yml` | New `cf` profile: datasource from `VCAP_SERVICES`, Config Server / Eureka / tracing off, `server.port=${PORT}` |
| `manifest.yml` | Cloud Foundry manifest for the three apps |

The default (local, HSQLDB) and `mysql` behaviour is unchanged; the `cf` profile is only active on Cloud Foundry.
The `visits` table has no foreign key to `pets` on PostgreSQL, because `pets` belongs to another service
and may not exist yet when `visits-service` starts.

## Prerequisites

1. **JDK 17+** and Maven (the repo includes `mvnw.cmd`).
2. **cf CLI v8** — download the Windows installer from https://github.com/cloudfoundry/cli/releases, then check with `cf version`.
3. In the BTP cockpit, your subaccount needs the entitlement **PostgreSQL, hyperscaler option** (service `postgresql-db`)
   with a plan (on a trial account: `trial`), and a Cloud Foundry space.
4. Memory quota for 3 × 1 GB (a trial space has 4 GB).

## Steps (Windows Command Prompt)

```bat
:: 1. Log in. The API endpoint is on the subaccount overview page in the BTP cockpit.
cf login -a https://api.cf.us10-001.hana.ondemand.com --sso
cf target -o <your-org> -s <your-space>

:: 2. Check the PostgreSQL service and the buildpack are available
cf marketplace -e postgresql-db
cf buildpacks

:: 3. Create the database (takes 10-20 minutes) and wait for "create succeeded"
cf create-service postgresql-db trial petclinic-db
cf service petclinic-db

:: 4. Build the three jars (from the repository root)
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
mvnw.cmd -pl spring-petclinic-customers-service,spring-petclinic-vets-service,spring-petclinic-visits-service -am clean package -DskipTests

:: 5. Deploy all three apps (reads manifest.yml)
cf push

:: 6. Check status and routes
cf apps
```

## Testing

Use the routes shown by `cf apps`:

```bat
curl https://<customers-route>/owners
curl https://<customers-route>/petTypes
curl https://<vets-route>/vets
curl https://<visits-route>/owners/*/pets/7/visits
curl https://<customers-route>/actuator/health
```

## Troubleshooting

```bat
cf logs customers-service --recent
cf env customers-service
cf restage customers-service
```

- **Staging fails on the buildpack**: if `sap_java_buildpack_jakarta` is not in `cf buildpacks`, change it in
  `manifest.yml` to `java_buildpack`, and replace the two `JBP_CONFIG_*` lines with
  `JBP_CONFIG_OPEN_JDK_JRE: '{ jre: { version: 21.+ } }'`.
- **`Could not resolve placeholder 'vcap.services.petclinic-db...'`**: the service is not bound or has another name;
  check with `cf services`.
- **SSL / `pg_hba.conf` errors**: the JDBC URL uses `sslmode=require`; check the credentials in `cf env`.

## Cleanup

```bat
cf delete customers-service -r -f
cf delete vets-service -r -f
cf delete visits-service -r -f
cf delete-service petclinic-db -f
```
