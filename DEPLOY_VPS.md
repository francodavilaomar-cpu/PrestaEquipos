# Despliegue de Sistema de Préstamos en VPS (Docker + SQL Server)

Guía adaptada a este proyecto (`prestamos_equipos`). Sigue el manual de tu maestro, pero con estos valores propios.

## Datos del proyecto
- Base de datos: `prestamos_equipos`
- Usuario de BD: `sa` (la app usa `sa` por defecto)
- Puerto de la app: `8080`
- Puerto de SQL Server: `1433`
- Imagen SQL Server (tu PC es 2025): `mcr.microsoft.com/mssql/server:2025-latest`
- La app crea automáticamente la base y datos iniciales al arrancar (no necesitas restaurar un `.bak`).

## 1. Empaquetar y subir (en tu PC)
```powershell
cd C:\sistema-prestamos
tar --exclude=node_modules --exclude=target --exclude=.git --exclude=.idea --exclude=.env -czf $env:USERPROFILE\Desktop\sistema-prestamos.tar.gz .
scp $env:USERPROFILE\Desktop\sistema-prestamos.tar.gz root@TU_IP:/opt/sistema-prestamos/
```

## 2. En el VPS
```bash
mkdir -p /opt/sistema-prestamos
cd /opt/sistema-prestamos
tar -xzf sistema-prestamos.tar.gz
```

## 3. Crear `.env` (solo en el VPS)
```bash
cd /opt/sistema-prestamos
printf 'DB_SA_PASSWORD=Sa#%s\n' "$(openssl rand -hex 12)" > .env
chmod 600 .env
cat .env
```
Guarda esa contraseña; la necesitarás para SQL Server.

## 4. Crear `docker-compose.override.yml` (solo en el VPS)
```bash
cat > docker-compose.override.yml <<'EOF'
services:
  db:
    image: mcr.microsoft.com/mssql/server:2025-latest
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: ${DB_SA_PASSWORD}
    ports:
      - "127.0.0.1:1433:1433"
    volumes:
      - mssql_data:/var/opt/mssql
    restart: unless-stopped

  app:
    environment:
      PRESTAMOS_DB_HOST: db
      PRESTAMOS_DB_PORT: 1433
      PRESTAMOS_DB_NAME: prestamos_equipos
      PRESTAMOS_DB_USER: sa
      PRESTAMOS_DB_PASS: ${DB_SA_PASSWORD}
      PRESTAMOS_DB_TRUST_CERT: "true"
    ports:
      - "127.0.0.1:8080:8080"
    depends_on:
      - db
    restart: unless-stopped

volumes:
  mssql_data:
EOF
```

## 5. Levantar SQL Server primero
```bash
cd /opt/sistema-prestamos
docker compose --profile sqlserver-docker up -d db 2>/dev/null || docker compose up -d db
docker compose ps
```
Espera a que `db` esté `healthy` o `Up`. La primera vez descarga la imagen (~1.5 GB).

## 6. Levantar la aplicación
```bash
cd /opt/sistema-prestamos
docker compose up --build -d app
docker compose logs --tail 40 app
```
La app creará la base `prestamos_equipos` y los datos iniciales (incluido el usuario admin).

## 7. Probar en el VPS
```bash
curl -I http://127.0.0.1:8080/
```
Debe responder `200` o `302`.

## 8. Dominio y HTTPS (Caddy)
Instala Caddy y configura tu dominio:
```bash
apt install -y caddy
cat > /etc/caddy/Caddyfile <<'EOF'
tudominio.com, www.tudominio.com {
    reverse_proxy 127.0.0.1:8080
}
EOF
caddy validate --config /etc/caddy/Caddyfile
systemctl reload caddy
```
Configura el DNS (registro A `@` → IP del VPS, elimina AAAA al parking).

## 9. Firewall (panel del proveedor)
Permite solo:
- TCP 22 (SSH)
- TCP 80 (HTTP)
- TCP 443 (HTTPS)
Bloquea el resto. Verifica desde tu PC:
```powershell
Test-NetConnection TU_IP -Port 1433   # debe fallar
Test-NetConnection TU_IP -Port 8080   # debe fallar
Test-NetConnection tudominio.com -Port 443  # debe funcionar
```

## 10. Actualizar en el futuro
En tu PC:
```powershell
cd C:\sistema-prestamos
tar --exclude=node_modules --exclude=target --exclude=.git --exclude=.idea --exclude=.env -czf $env:USERPROFILE\Desktop\sistema-prestamos.tar.gz .
scp $env:USERPROFILE\Desktop\sistema-prestamos.tar.gz root@TU_IP:/opt/sistema-prestamos/
```
En el VPS:
```bash
cd /opt/sistema-prestamos
tar -xzf sistema-prestamos.tar.gz
docker compose up --build -d app
```
No borres `.env` ni `docker-compose.override.yml`.

## Notas
- Usuario inicial: `admin@universidad.edu` / `admin123` (cámbialo después de entrar).
- Las fotos de perfil se pierden al reconstruir el contenedor (pendiente de volumen).
- Nunca ejecutes `docker compose down -v` en el servidor (borra la base).