#!/usr/bin/env bash

API_KEY="Inert your api key"

LOCATION=$(curl -sf "https://ipinfo.io/json")
if [[ -z "$LOCATION" ]]; then
    echo '{"text":"󰖑 N/A","tooltip":"Could not detect location"}'
    exit 0
fi

LAT=$(echo "$LOCATION" | grep -oP '"loc":\s*"\K[^,]+(?=,)')
LON=$(echo "$LOCATION" | grep -oP '"loc":\s*"[^,]+,\K[^"]+')
CITY=$(echo "$LOCATION" | grep -oP '"city":\s*"\K[^"]+')
REGION=$(echo "$LOCATION" | grep -oP '"region":\s*"\K[^"]+')

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
CONDITION=$(echo "$WEATHER" | grep -oP '"main":\s*"\K[^"]+' | head -1)
DESCRIPTION=$(echo "$WEATHER" | grep -oP '"description":\s*"\K[^"]+' | head -1)
TEMP=$(echo "$WEATHER" | grep -oP '"temp":\s*\K[0-9.-]+' | head -1)
FEELS=$(echo "$WEATHER" | grep -oP '"feels_like":\s*\K[0-9.-]+' | head -1)
HUMIDITY=$(echo "$WEATHER" | grep -oP '"humidity":\s*\K[0-9]+' | head -1)
TEMP_INT=$(printf "%.0f" "$TEMP")
FEELS_INT=$(printf "%.0f" "$FEELS")

# ── Map condition to Nerd Font v3 icon ────────────────────
case "$CONDITION" in
    Clear)        ICON="󰖙" ;;   # sun
    Clouds)
        CLOUD_DESC=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')
        if [[ "$CLOUD_DESC" == *"few"* ]]; then
            ICON="󰖕"             # sun + few clouds
        else
            ICON="󰖐"             # cloudy
        fi ;;
    Rain|Drizzle)  ICON="󰖗" ;;  # rain
    Thunderstorm)  ICON="󰖙" ;;  # thunder (use 󰙾 if available)
    Snow)          ICON="󰼶" ;;  # snow
    Mist|Fog|Haze|Smoke|Dust|Sand|Ash) ICON="󰖑" ;;  # fog
    Squall|Tornado) ICON="󰖝" ;; # wind
    *)             ICON="󰖑" ;;
esac

# ── Output JSON for waybar ────────────────────────────────
TEXT="${ICON} ${TEMP_INT}°C"
TOOLTIP="${CITY}, ${REGION}\n${DESCRIPTION^}\n󰔏 ${TEMP_INT}°C  (feels ${FEELS_INT}°C)\n󰖎 Humidity: ${HUMIDITY}%"

echo "{\"text\":\"${TEXT}\",\"tooltip\":\"${TOOLTIP}\"}"
