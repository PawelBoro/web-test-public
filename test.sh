curl -i -H 'Accept: application/xml' localhost:3000/api/health
curl -i -X POST -H 'Content-Type: text/plain' -d 'hello' localhost:3000/api/health
curl -i -H 'password: no token' localhost:3000/api/health
curl -i -H 'Accept: application/xml' localhost:3000/api/health
curl -i -H 'Accept: application/xml' localhost:3000/api/health
curl -i -H 'Accept: application/xml' localhost:3000/api/health


# Phase 1 curl checks. Usage: checks.sh <username> <password> [base-url]
U="$1"; P="$2"; B="${3:-http://localhost:3000}"
J='Content-Type: application/json'

show() { # title, curl args...
  local t="$1"; shift
  echo; echo "### $t"
  curl -s -i "$@" | tr -d '\r' | grep -iE '^(HTTP|content-type|www-authenticate)|^\{|^\[|^<'
}
login() { curl -s -X POST -H "$J" -d "{\"username\":\"$U\",\"password\":\"$1\"}" "$B/api/auth/login" | sed -E 's/.*"accessToken":"([^"]+)".*/\1/'; }

show "health -> 200" "$B/api/health"
show "Accept: application/xml -> 406" -H 'Accept: application/xml' "$B/api/health"
show "login text/plain -> 415" -X POST -H 'Content-Type: text/plain' -d 'hello' "$B/api/auth/login"
show "login malformed JSON -> 400" -X POST -H "$J" -d '{"username":' "$B/api/auth/login"
show "login wrong types -> 400" -X POST -H "$J" -d '{"username":1}' "$B/api/auth/login"
show "login wrong password -> 401" -X POST -H "$J" -d "{\"username\":\"$U\",\"password\":\"nope\"}" "$B/api/auth/login"
show "login unknown user -> 401 (same body)" -X POST -H "$J" -d '{"username":"ghost-user","password":"nope"}' "$B/api/auth/login"
show "login correct -> 200" -X POST -H "$J" -d "{\"username\":\"$U\",\"password\":\"$P\"}" "$B/api/auth/login"

T=$(login "$P")
show "password: no token -> 401" -X PUT -H "$J" -d '{"currentPassword":"x","newPassword":"long-enough-1"}' "$B/api/auth/password"
show "password: missing field -> 400" -X PUT -H "$J" -H "Authorization: Bearer $T" -d '{"currentPassword":"x"}' "$B/api/auth/password"
show "password: wrong current -> 403" -X PUT -H "$J" -H "Authorization: Bearer $T" -d '{"currentPassword":"wrong","newPassword":"long-enough-1"}' "$B/api/auth/password"
show "password: too short -> 422" -X PUT -H "$J" -H "Authorization: Bearer $T" -d "{\"currentPassword\":\"$P\",\"newPassword\":\"short\"}" "$B/api/auth/password"
show "forged token -> 401" -X POST -H 'Authorization: Bearer eyJhbGciOiJub25lIn0.eyJzdWIiOiJhZG1pbiJ9.' "$B/api/auth/logout"
show "logout (no body) -> 204" -X POST -H "Authorization: Bearer $T" "$B/api/auth/logout"
show "same token after logout -> 401" -X PUT -H "$J" -H "Authorization: Bearer $T" -d "{\"currentPassword\":\"$P\",\"newPassword\":\"long-enough-1\"}" "$B/api/auth/password"
show "GET /api/nonexistent -> 404" "$B/api/nonexistent"
show "non-API 404 still HTML page" "$B/nothing-here"
echo; echo "### helmet headers on /api/health"
curl -s -I "$B/api/health" | tr -d '\r' | grep -iE '^(x-content-type-options|content-security-policy)' | cut -c1-90

node "/mnt/c/Users/pawel/OneDrive/Dokumenty/Studia/2 rok/Zaawansowane aplikacje internetowe/Projekt/Pliki pomocnicze (skrypt testujący i kontrakt API)-20261010/zai-tests.mjs" \
  --app http://localhost:3000 --user qa_tmp_admin --pass 'QaTmpPass-2026' --stage E1

node "/mnt/c/Users/pawel/OneDrive/Dokumenty/Studia/2 rok/Zaawansowane aplikacje internetowe/Projekt/Pliki pomocnicze (skrypt testujący i kontrakt API)-20261010/zai-tests.mjs" \
  --app http://localhost:3000 \
  --user "$(grep '^ADMIN_USERNAME=' .env | cut -d= -f2-)" \
  --pass "$(grep '^ADMIN_PASSWORD=' .env | cut -d= -f2-)" \
  --stage E1


APP=https://zaapin.onrender.com
curl -s $APP/api/health

read -rs "PW?Admin password: "; echo
TOKEN=$(curl -s -X POST $APP/api/auth/login -H 'Content-Type: application/json' \
  -d "{\"username\":\"admin\",\"password\":\"$PW\"}" | node -pe 'JSON.parse(require("fs").readFileSync(0)).accessToken')
curl -s -w '\n%{http_code}\n' $APP/api/series -H "Authorization: Bearer $TOKEN"

cd "/mnt/c/Users/pawel/OneDrive/Dokumenty/Studia/2 rok/Zaawansowane aplikacje internetowe/Projekt/Pliki pomocnicze (skrypt testujący i kontrakt API)-20261010/"
node zai-tests.mjs --app $APP --user admin --pass "$PW" --stage E1
node zai-tests.mjs --app $APP --user admin --pass "$PW" --stage E2
