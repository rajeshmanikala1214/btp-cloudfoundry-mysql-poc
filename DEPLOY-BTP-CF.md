# Deploying to SAP BTP Cloud Foundry from the command line (feature/postgresql)

This branch deploys the three database-backed services — `customers-service`, `vets-service`
and `visits-service` — as separate Cloud Foundry apps sharing one SAP BTP PostgreSQL instance.
`vets-service` keeps its `vets` cache in an SAP BTP Redis instance.
Config Server, Eureka, API Gateway, Admin Server and GenAI service are **not** deployed.

## What changed on this branch

| File | Change |
|---|---|
| `spring-petclinic-{customers,vets,visits}-service/pom.xml` | Added `org.postgresql:postgresql` (runtime) |
| `spring-petclinic-vets-service/pom.xml` | Added `spring-boot-starter-data-redis` |
| `.../src/main/resources/db/postgresql/{schema,data}.sql` | PostgreSQL versions of the MySQL scripts |
| `.../src/main/resources/application.yml` | New `cf` profile: datasource from `VCAP_SERVICES`, Config Server / Eureka / tracing off, `server.port=${PORT}`; for vets-service also the Redis cache |
| `spring-petclinic-vets-service/.../model/{Vet,Specialty}.java` | `implements Serializable`, so cached vets can be stored in Redis |
| `manifest.yml` | Cloud Foundry manifest for the three apps |

The default (local, HSQLDB, Caffeine cache) and `mysql` behaviour is unchanged; the `cf` profile is only active on Cloud Foundry.
The `visits` table has no foreign key to `pets` on PostgreSQL, because `pets` belongs to another service
and may not exist yet when `visits-service` starts.

## Service instances

| Instance name | Service (technical name) | Plan | Used by |
|---|---|---|---|
| `petclinic-db` | PostgreSQL, Hyperscaler Option (`postgresql-db`) | `trial` | all three apps |
| `petclinic-redis` | Redis, Hyperscaler Option (`redis-cache`) | `trial` | `vets-service` |

The names must match exactly: the `cf` profile reads `vcap.services.petclinic-db.*` and `vcap.services.petclinic-redis.*`.

## Prerequisites

1. **JDK 17+** and Maven (the repo includes `mvnw.cmd`).
2. **cf CLI v8** — download the Windows installer from https://github.com/cloudfoundry/cli/releases, then check with `cf version`.
3. In the BTP cockpit, the subaccount needs the entitlements **PostgreSQL, Hyperscaler Option** and
   **Redis, Hyperscaler Option** (on a trial account: plan `trial`).
4. Your user must be **Space Developer** in the target space (Cloud Foundry → Spaces → *space* → Space Members).
   Org Manager alone is not enough: creating services then fails with "You are not authorized to perform the requested action".
5. Memory quota for 3 × 1 GB (a trial space has 4 GB).

## Steps (Windows PowerShell)

```powershell
# 1. Log in. The API endpoint is on the subaccount overview page in the BTP cockpit.
cf login -a https://api.cf.us10-001.hana.ondemand.com -o <your-org> -s <your-space>

# 2. Check the services and the buildpack are available
cf marketplace -e postgresql-db
cf marketplace -e redis-cache
cf buildpacks

# 3. Create PostgreSQL and Redis (each takes 10-20 minutes); wait for "create succeeded"
cf create-service postgresql-db trial petclinic-db
cf create-service redis-cache trial petclinic-redis
cf service petclinic-db
cf service petclinic-redis

# 4. Build the three jars (from the repository root)
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
.\mvnw.cmd -pl spring-petclinic-customers-service,spring-petclinic-vets-service,spring-petclinic-visits-service -am clean package -DskipTests

# 5. Deploy all three apps (reads manifest.yml)
cf push

# 6. Check status and routes
cf apps
```

In Command Prompt instead of PowerShell, use `set "JAVA_HOME=C:\Program Files\Java\jdk-17"` and `mvnw.cmd ...`.

## Testing

Use the routes shown by `cf apps`:

```powershell
curl.exe https://<customers-route>/owners
curl.exe https://<customers-route>/petTypes
curl.exe https://<vets-route>/vets
curl.exe https://<visits-route>/owners/*/pets/7/visits
curl.exe https://<vets-route>/actuator/health
```

`/actuator/health` on vets-service includes the database and Redis connections, so `UP` there means both work.
The second `GET /vets` within 60 seconds is served from Redis.

## Troubleshooting

```powershell
cf logs vets-service --recent
cf env vets-service
cf restage vets-service
```

- **Staging fails on the buildpack**: if `sap_java_buildpack_jakarta` is not in `cf buildpacks`, change it in
  `manifest.yml` to `java_buildpack`, and replace the two `JBP_CONFIG_*` lines with
  `JBP_CONFIG_OPEN_JDK_JRE: '{ jre: { version: 21.+ } }'`.
- **`Could not resolve placeholder 'vcap.services.petclinic-db...'`** (or `petclinic-redis`): the service is not bound,
  has another name, or its credentials use different keys; check with `cf services` and `cf env <app>`.
- **SSL / `pg_hba.conf` errors**: the JDBC URL uses `sslmode=require`; check the credentials in `cf env`.
- **Redis connection or TLS errors**: the cf profile connects with TLS (`spring.data.redis.ssl.enabled=true`);
  compare with the `tls` flag in the `petclinic-redis` credentials in `cf env vets-service`.

## Cleanup

```powershell
cf delete customers-service -r -f
cf delete vets-service -r -f
cf delete visits-service -r -f
cf delete-service petclinic-redis -f
cf delete-service petclinic-db -f
```
