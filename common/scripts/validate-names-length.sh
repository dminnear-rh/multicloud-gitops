#!/usr/bin/env bash

MAX_CALCULATED_LENGTH=47

print_explanation() {
  echo "--------------------------------------------------------------------------------"
  echo "Validation Explanation:"
  echo "This script ensures that generated Kubernetes resource names do not exceed the 63-character limit."
  echo "A DNS-compatible name is constructed in the 'clustergroup' Helm chart using the following pattern:"
  echo "  -> {{ .Values.clusterGroup.name }}-gitops-server-{{ .Values.global.pattern }}-{{ .Values.clusterGroup.name }}"
  echo ""
  echo "The total length is calculated as:"
  echo "  (2 * length of 'clusterGroup.name') + length of 'global.pattern' + 15 (for '-gitops-server-') + 1 (for the namespace separator '-')"
  echo ""
  echo "To stay under the 63-character limit, the variable part of the name must be less than $MAX_CALCULATED_LENGTH characters:"
  echo "  (2 * length of 'clusterGroup.name') + length of 'global.pattern' < $MAX_CALCULATED_LENGTH"
  echo "--------------------------------------------------------------------------------"
}

if [ ! -f "values-global.yaml" ]; then
  echo "Error: Global values file 'values-global.yaml' not found."
  exit 1
fi

global_pattern=$(yq .global.pattern "values-global.yaml")

if [ "$global_pattern" == "null" ] || [ -z "$global_pattern" ]; then
  echo "Error: '.global.pattern' not found or is empty in 'values-global.yaml'."
  exit 1
fi
pattern_length=${#global_pattern}

echo "Found global pattern '$global_pattern' with length $pattern_length."
echo ""

validation_failed=false

for file in values-*.yaml; do
  group_name=$(yq .clusterGroup.name "$file")

  if [ "$group_name" != "null" ] && [ -n "$group_name" ]; then
    group_name_length=${#group_name}
    total_length=$(( (2 * group_name_length) + pattern_length ))

    echo "Checking file: $file"
    echo "  -> Cluster Group Name: '$group_name' (length: $group_name_length)"
    echo "  -> Calculated Length: (2 * $group_name_length) + $pattern_length = $total_length"

    if [ "$total_length" -ge "$MAX_CALCULATED_LENGTH" ]; then
      echo "    FAILED: Calculated length ($total_length) is not less than $MAX_CALCULATED_LENGTH."
      echo ""
      validation_failed=true
    else
      echo "    PASSED: Calculated length ($total_length) is less than $MAX_CALCULATED_LENGTH."
      echo ""
    fi
  fi
done

# --- Final Output and Exit Status ---

if $validation_failed; then
  echo "================================================================================"
  echo "========= One or more cluster group names failed the length validation. ========"
  echo "================================================================================"
  print_explanation
  exit 1
else
  echo "All cluster group names passed the length validation."
  exit 0
fi
