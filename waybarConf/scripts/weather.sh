#!/usr/bin/env bash

API_KEY="9c4c74a42bec1504305b93254a895e91"

LOCATION=$(curl -sf "https://ipinfo.io/json")
if [[ -z "$LOCATION" ]]; then
  echo '{"text":"󰖑 N/A","tooltip":"Could not detect location"}'
  exit 0
fi

LAT=$(echo "$LOCATION" | jq -r '.loc | split(",")[0]')
LON=$(echo "$LOCATION" | jq -r '.loc | split(",")[1]')
CITY=$(echo "$LOCATION" | jq -r '.city')
REGION=$(echo "$LOCATION" | jq -r '.region')

if [[ -z "$LAT" || -z "$LON" ]]; then
  echo '{"text":"󰖑 N/A","tooltip":"Could not parse location"}'
  exit 0
fi

# ── Fetch weather from OWM ────────────────────────────────
WEATHER=$(curl -sf \
  "https://api.openweathermap.org/data/2.5/weather?lat=${LAT}&lon=${LON}&units=metric&appid=${API_KEY}")

if [[ -z "$WEATHER" ]]; then
  echo '{"text":"󰖑 N/A","tooltip":"Could not reach OpenWeatherMap"}'
  exit 0
fi

# ── Parse fields ──────────────────────────────────────────
CONDITION=$(echo "$WEATHER" | jq -r '.weather[0].main')
DESCRIPTION=$(echo "$WEATHER" | jq -r '.weather[0].description')
TEMP=$(echo "$WEATHER" | jq -r '.main.temp')
FEELS=$(echo "$WEATHER" | jq -r '.main.feels_like')
HUMIDITY=$(echo "$WEATHER" | jq -r '.main.humidity')
TEMP_INT=$(printf "%.0f" "$TEMP")
FEELS_INT=$(printf "%.0f" "$FEELS")

# ── Map condition to Nerd Font v3 icon ────────────────────
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

# ── Output JSON for waybar ────────────────────────────────
TEXT="${ICON} ${TEMP_INT}°C"
TOOLTIP="${CITY}, ${REGION}\n${DESCRIPTION^}\n󰔏 ${TEMP_INT}°C  (feels ${FEELS_INT}°C)\n󰖎 Humidity: ${HUMIDITY}%"

echo "{\"text\":\"${TEXT}\",\"tooltip\":\"${TOOLTIP}\"}"
