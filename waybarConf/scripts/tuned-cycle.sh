#!/usr/bin/env bash
PROFILES=("powersave" "balanced-battery" "balanced" "throughput-performance")
ICONS=($'\uf06c' $'\uf242' $'\uf0ad' $'\uf135')
LABELS=("SAVE" "BATT" "BAL" "PERF")

current=$(tuned-adm active 2>/dev/null | awk "{print \$NF}")

idx=0
for i in "${!PROFILES[@]}"; do
  [[ "${PROFILES[$i]}" == "$current" ]] && idx=$i && break
done

case "$1" in
  click)
    next=$(( (idx + 1) % ${#PROFILES[@]} ))
    sudo tuned-adm profile "${PROFILES[$next]}"
    ;;
  *)
    echo "${ICONS[$idx]} ${LABELS[$idx]}"
    ;;
esac
