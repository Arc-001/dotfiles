#!/usr/bin/env bash

API_KEY="insert your api key here"

# Set this to skip location detection and use a fixed city (e.g. "Chennai,IN")
CITY_OVERRIDE="Chennai,IN"

if [[ -n "$CITY_OVERRIDE" ]]; then
  GEO=$(curl -sf --max-time 5 \
    "https://nominatim.openstreetmap.org/search?q=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote('$CITY_OVERRIDE'))")&format=json&limit=1" \
    -H "User-Agent: waybar-weather/1.0")
  LAT=$(echo "$GEO" | jq -r '.[0].lat')
  LON=$(echo "$GEO" | jq -r '.[0].lon')
  CITY=$(echo "$CITY_OVERRIDE" | cut -d',' -f1)
  REGION=""
  if [[ -z "$LAT" || "$LAT" == "null" ]]; then
    echo '{"text":"󰖑 N/A","tooltip":"Could not geocode city override"}'
    exit 0
  fi
else

  # Get device location via GeoClue2; fall back to IP-based if unavailable
  GEOCLUE_LOC=$(
    python3 - <<'PYEOF' 2>/dev/null
import gi, signal
gi.require_version('Geoclue', '2.0')
from gi.repository import Geoclue, GLib

loop = GLib.MainLoop()
result = {}

def on_location(client, _):
    loc = client.get_location()
    if loc:
        result['lat'] = loc.get_property('latitude')
        result['lon'] = loc.get_property('longitude')
    loop.quit()

def timeout():
    loop.quit()
    return False

try:
    client = Geoclue.Simple.new_sync('waybar-weather', Geoclue.AccuracyLevel.CITY, None)
    loc = client.get_location()
    if loc:
        print(f"{loc.get_property('latitude')},{loc.get_property('longitude')}")
except Exception:
    pass
PYEOF
  )

  if [[ -n "$GEOCLUE_LOC" ]]; then
    LAT=$(echo "$GEOCLUE_LOC" | cut -d',' -f1)
    LON=$(echo "$GEOCLUE_LOC" | cut -d',' -f2)
    CITY="Device Location"
    REGION=""
  else
    # IP fallback
    IPINFO=$(curl -sf --max-time 5 "https://ipinfo.io/json")
    if [[ -z "$IPINFO" ]]; then
      echo '{"text":"󰖑 N/A","tooltip":"Could not detect location"}'
      exit 0
    fi
    LAT=$(echo "$IPINFO" | jq -r '.loc | split(",")[0]')
    LON=$(echo "$IPINFO" | jq -r '.loc | split(",")[1]')
    CITY=$(echo "$IPINFO" | jq -r '.city')
    REGION=$(echo "$IPINFO" | jq -r '.region')
  fi

fi # end CITY_OVERRIDE else

if [[ -z "$LAT" || -z "$LON" ]]; then
  echo '{"text":"󰖑 N/A","tooltip":"Could not parse location"}'
  exit 0
fi

# Reverse geocode city name from GeoClue coords
if [[ "$CITY" == "Device Location" ]]; then
  GEO=$(curl -sf --max-time 5 "https://nominatim.openstreetmap.org/reverse?lat=${LAT}&lon=${LON}&format=json" \
    -H "User-Agent: waybar-weather/1.0")
  if [[ -n "$GEO" ]]; then
    CITY=$(echo "$GEO" | jq -r '.address.city // .address.town // .address.village // "Unknown"')
    REGION=$(echo "$GEO" | jq -r '.address.state // ""')
  fi
fi

WEATHER=$(curl -sf --max-time 5 \
  "https://api.openweathermap.org/data/2.5/weather?lat=${LAT}&lon=${LON}&units=metric&appid=${API_KEY}")

if [[ -z "$WEATHER" ]]; then
  echo '{"text":"󰖑 N/A","tooltip":"Could not reach OpenWeatherMap"}'
  exit 0
fi

CONDITION=$(echo "$WEATHER" | jq -r '.weather[0].main')
DESCRIPTION=$(echo "$WEATHER" | jq -r '.weather[0].description')
TEMP=$(echo "$WEATHER" | jq -r '.main.temp')
FEELS=$(echo "$WEATHER" | jq -r '.main.feels_like')
HUMIDITY=$(echo "$WEATHER" | jq -r '.main.humidity')
TEMP_INT=$(printf "%.0f" "$TEMP")
FEELS_INT=$(printf "%.0f" "$FEELS")

case "$CONDITION" in
Clear) ICON="󰖙" ;;
Clouds)
  if [[ "$DESCRIPTION" == *"few"* ]]; then
    ICON="󰖕"
  else
    ICON="󰖐"
  fi
  ;;
Rain | Drizzle) ICON="󰖗" ;;
Thunderstorm) ICON="󰙾" ;;
Snow) ICON="󰼶" ;;
Mist | Fog | Haze | Smoke | Dust | Sand | Ash) ICON="󰖑" ;;
Squall | Tornado) ICON="󰖝" ;;
*) ICON="󰖑" ;;
esac

LOCATION_LINE="${CITY}${REGION:+, $REGION}"
TEXT="${ICON} ${TEMP_INT}°C"
TOOLTIP="${LOCATION_LINE}\n${DESCRIPTION^}\n󰔏 ${TEMP_INT}°C  (feels ${FEELS_INT}°C)\n󰖎 Humidity: ${HUMIDITY}%"

echo "{\"text\":\"${TEXT}\",\"tooltip\":\"${TOOLTIP}\"}"
