# OSAC Chart Values Pattern

This document describes the pattern for transforming high-level configuration into detailed subchart values.

## Overview

The OSAC parent chart supports both:
1. **High-level properties** for convenience (e.g., `global.services.*.enabled`)
2. **Detailed subchart values** for fine-grained control (e.g., `operator.controllers.clusterOrder`)

Subcharts contain template helpers that compute their configuration from high-level properties, while still allowing direct value overrides.

## Pattern

### Parent Chart (`osac-installer/charts/osac`)

**values.yaml**: Defines high-level properties under `global` (example showing selective enablement):

```yaml
global:
  services:
    caas:
      enabled: true
    vmaas:
      enabled: true
    bmaas:
      enabled: true
    maas:
      enabled: true
```

**Default behavior**: All four services default to `enabled: true` for backward compatibility. Set to `false` to disable specific services.

### Subchart (`osac-operator/charts/operator`)

**templates/_helpers.tpl**: Computes values from `global` with local override support:

```yaml
{{- define "osac-operator.controllerEnabled" -}}
{{- $ctx := index . 0 -}}
{{- $ctrlKey := index . 1 -}}
{{- $svcKey := index . 2 -}}
{{- $ctrlVal := index $ctx.Values.controllers $ctrlKey -}}
{{- if $ctrlVal | kindIs "invalid" | not -}}
{{- $ctrlVal -}}
{{- else -}}
{{- $enabled := true -}}
{{- if $ctx.Values.global -}}
{{- if $ctx.Values.global.services -}}
{{- $svc := index $ctx.Values.global.services $svcKey -}}
{{- if $svc -}}
{{- if hasKey $svc "enabled" -}}
{{- $enabled = $svc.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $enabled -}}
{{- end -}}
{{- end }}
```

**Key implementation details:**
- Takes three parameters: context, controller key, service key (eliminates code duplication)
- Initialize fallback to `true` (backward compatibility)
- Guard `.Values.global` access with nil check (subchart can be linted standalone)
- Use `hasKey` to check if `enabled` key exists (preserves explicit `false` values)
- Never use `| default true` pattern (treats `false` as falsy)
- **Both** subchart and parent chart `values.yaml` must not define defaults for computed properties
  (otherwise Helm merges them and the helpers never reach the `global` computation branch)

**templates/deployment.yaml**: Uses the helper instead of reading `.Values` directly:

```yaml
- name: OSAC_ENABLE_CLUSTER_CONTROLLER
  value: {{ include "osac-operator.controllerEnabled" (list . "clusterOrder" "caas") | quote }}
- name: OSAC_ENABLE_COMPUTE_INSTANCE_CONTROLLER
  value: {{ include "osac-operator.controllerEnabled" (list . "computeInstance" "vmaas") | quote }}
- name: OSAC_ENABLE_BAREMETAL_INSTANCE_CONTROLLER
  value: {{ include "osac-operator.controllerEnabled" (list . "bareMetalInstance" "bmaas") | quote }}
```

## User Experience

### Scenario 1: High-level configuration (common case)

User sets service enablement:

```yaml
global:
  services:
    caas:
      enabled: false
    vmaas:
      enabled: true
    bmaas:
      enabled: false
    maas:
      enabled: false
```

**Result**: 
- `operator.controllers.computeInstance: true`
- `operator.controllers.clusterOrder: false`

### Scenario 2: Fine-grained override

User overrides a specific controller:

```yaml
global:
  services:
    caas:
      enabled: false
    vmaas:
      enabled: true

operator:
  controllers:
    clusterOrder: true  # Override: enable even though caas is disabled
```

**Result**:
- `operator.controllers.computeInstance: true` (computed from global.services.vmaas.enabled)
- `operator.controllers.clusterOrder: true` (explicit override)

## Implementation Checklist

When adding a new high-level property:

1. [ ] Add property to parent chart `values.yaml` under `global`
2. [ ] Document the property and which subchart values it affects
3. [ ] In affected subchart `_helpers.tpl`, create a helper that:
   - Checks if local value is explicitly set (`kindIs "invalid" | not`)
   - If set, uses local value
   - Otherwise, computes from `global` property
4. [ ] Update subchart templates to use the helper
5. [ ] Test both high-level and override scenarios

## Design Principles

1. **Computation lives with consumption**: Subcharts compute their own values from `global`, not the parent
2. **Overrides always win**: Explicit subchart values take precedence over computed values
3. **Backwards compatible**: Existing deployments with detailed values continue to work
4. **Clear relationships**: Document which high-level properties affect which subchart values
