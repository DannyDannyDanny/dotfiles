#!/usr/bin/env python3
"""Regenerate the themed 'fleet' Grafana dashboards.

Dev tool — run `python3 modules/grafana-dashboards/generate.py` after editing,
then commit the resulting fleet-*.json. NOT used at nix build time; the .nix
module just vendors the JSON output. node-exporter-full.json (grafana.com
#1860) is vendored separately and is NOT produced here.

Panels reference the fixed Prometheus datasource uid 'prometheus'. Series are
labeled by `alias` (ship name) via the scrape config; every dashboard has a
multi-select `ship` template variable and filters queries on alias=~"$ship".
"""
import json, os

OUT = os.path.dirname(os.path.abspath(__file__))
DS = {"type": "prometheus", "uid": "prometheus"}
F = 'alias=~"$ship"'  # injected into every selector

def tgt(expr, legend="", refId="A", instant=False):
    return {"datasource": DS, "expr": expr, "refId": refId,
            "legendFormat": legend, "editorMode": "code",
            "instant": instant, "range": not instant}

def thresholds(steps):
    return {"mode": "absolute", "steps": steps}

PCT_STEPS = [{"value": None, "color": "green"},
             {"value": 70, "color": "yellow"},
             {"value": 85, "color": "red"}]
TEMP_STEPS = [{"value": None, "color": "green"},
              {"value": 60, "color": "yellow"},
              {"value": 80, "color": "red"}]

def fc(unit="", mn=None, mx=None, steps=None, mappings=None, decimals=None):
    d = {"unit": unit, "thresholds": thresholds(steps or [{"value": None, "color": "green"}]),
         "color": {"mode": "thresholds"}, "mappings": mappings or []}
    if mn is not None: d["min"] = mn
    if mx is not None: d["max"] = mx
    if decimals is not None: d["decimals"] = decimals
    return {"defaults": d, "overrides": []}

_pid = [0]
def pid():
    _pid[0] += 1
    return _pid[0]

def panel(ptype, title, x, y, w, h, targets, fieldConfig, options, pluginVersion="11.0.0"):
    return {"id": pid(), "type": ptype, "title": title,
            "gridPos": {"h": h, "w": w, "x": x, "y": y},
            "datasource": DS, "targets": targets,
            "fieldConfig": fieldConfig, "options": options,
            "pluginVersion": pluginVersion}

def gauge(title, x, y, w, h, expr, legend, unit="percent", mx=100, steps=None):
    return panel("gauge", title, x, y, w, h, [tgt(expr, legend, instant=True)],
                 fc(unit=unit, mn=0, mx=mx, steps=steps or PCT_STEPS),
                 {"reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
                  "orientation": "auto", "showThresholdLabels": False,
                  "showThresholdMarkers": True})

def bargauge(title, x, y, w, h, expr, legend, unit="percent", mx=100, steps=None):
    # mx defaults to 100 so percent bars scale 0–100 (absolute), not relative
    # to the panel's own max. Pass mx=None for non-percent units (e.g. Bps).
    return panel("bargauge", title, x, y, w, h, [tgt(expr, legend, instant=True)],
                 fc(unit=unit, mn=0, mx=mx, steps=steps or PCT_STEPS),
                 {"reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
                  "orientation": "horizontal", "displayMode": "gradient",
                  "showUnfilled": True, "valueMode": "color"})

def stat(title, x, y, w, h, expr, legend, unit="", steps=None, mappings=None,
         colorMode="value", textMode="value_and_name", graphMode="none", instant=True):
    return panel("stat", title, x, y, w, h, [tgt(expr, legend, instant=instant)],
                 fc(unit=unit, steps=steps or [{"value": None, "color": "green"}], mappings=mappings),
                 {"reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
                  "orientation": "auto", "colorMode": colorMode, "graphMode": graphMode,
                  "justifyMode": "auto", "textMode": textMode})

def timeseries(title, x, y, w, h, targets, unit="", steps=None, fillOpacity=10, stacking="none"):
    f = fc(unit=unit, steps=steps or [{"value": None, "color": "green"}])
    f["defaults"]["custom"] = {
        "drawStyle": "line", "lineInterpolation": "smooth", "lineWidth": 2,
        "fillOpacity": fillOpacity, "gradientMode": "opacity", "showPoints": "never",
        "pointSize": 5, "spanNulls": True, "axisPlacement": "auto",
        "stacking": {"mode": stacking, "group": "A"}, "scaleDistribution": {"type": "linear"}}
    f["defaults"]["color"] = {"mode": "palette-classic"}
    return panel("timeseries", title, x, y, w, h, targets, f,
                 {"legend": {"displayMode": "table", "placement": "right",
                             "calcs": ["lastNotNull", "max"], "showLegend": True},
                  "tooltip": {"mode": "multi", "sort": "desc"}})

def ship_var():
    q = 'label_values(up{job="node"}, alias)'
    return {"name": "ship", "label": "Ship", "type": "query", "datasource": DS,
            "query": {"qryType": 1, "query": q, "refId": "StandardVariableQuery"},
            "definition": q, "refresh": 2, "includeAll": True, "multi": True,
            "allValue": ".*", "current": {"selected": True, "text": ["All"], "value": ["$__all"]},
            "options": [], "regex": "", "sort": 1, "hide": 0, "skipUrlSync": False}

def dashboard(uid, title, tags, panels, refresh="30s", frm="now-6h"):
    return {"uid": uid, "title": title, "tags": tags, "editable": True,
            "timezone": "browser", "schemaVersion": 39, "version": 1,
            "refresh": refresh, "graphTooltip": 1, "fiscalYearStartMonth": 0,
            "liveNow": False, "weekStart": "", "style": "dark", "links": [],
            "time": {"from": frm, "to": "now"},
            "timepicker": {}, "templating": {"list": [ship_var()]},
            "annotations": {"list": [{"builtIn": 1, "type": "dashboard",
                "name": "Annotations & Alerts", "enable": True, "hide": True,
                "iconColor": "rgba(0, 211, 255, 1)",
                "datasource": {"type": "grafana", "uid": "-- Grafana --"}}]},
            "panels": panels}

# --- expressions (all filtered by the $ship template var) ---
CPU = f'100 * (1 - avg by (alias) (rate(node_cpu_seconds_total{{mode="idle",{F}}}[5m])))'
RAM = f'100 * (1 - node_memory_MemAvailable_bytes{{{F}}} / node_memory_MemTotal_bytes{{{F}}})'
DISK = (f'100 * (1 - node_filesystem_avail_bytes{{mountpoint="/",fstype="ext4",{F}}} '
        f'/ node_filesystem_size_bytes{{mountpoint="/",fstype="ext4",{F}}})')
UP = f'up{{job="node",{F}}}'
UPTIME = f'time() - node_boot_time_seconds{{{F}}}'
LOAD = f'node_load1{{{F}}}'
NET_RX = f'sum by (alias) (rate(node_network_receive_bytes_total{{device!~"lo",{F}}}[5m]))'
NET_TX = f'sum by (alias) (rate(node_network_transmit_bytes_total{{device!~"lo",{F}}}[5m]))'
NET_TOT = (f'sum by (alias) (rate(node_network_receive_bytes_total{{device!~"lo",{F}}}[5m]) '
           f'+ rate(node_network_transmit_bytes_total{{device!~"lo",{F}}}[5m]))')
TEMP = f'max by (alias) (node_hwmon_temp_celsius{{{F}}})'

UP_MAP = [{"type": "value", "options": {
    "0": {"text": "⚓ ADRIFT", "color": "red", "index": 1},
    "1": {"text": "⛵ AFLOAT", "color": "green", "index": 0}}}]
UP_STEPS = [{"value": None, "color": "red"}, {"value": 1, "color": "green"}]

dashboards = {}

# 1) Fleet Command Bridge
_pid[0] = 0
p = []
p.append(stat("🚢 Fleet Muster — who's afloat", 0, 0, 24, 5, UP, "{{alias}}",
              steps=UP_STEPS, mappings=UP_MAP, colorMode="background", textMode="value_and_name"))
p.append(gauge("⚙️ CPU load", 0, 5, 8, 8, CPU, "{{alias}}"))
p.append(gauge("🧠 Memory used", 8, 5, 8, 8, RAM, "{{alias}}"))
p.append(gauge("💾 Root disk used", 16, 5, 8, 8, DISK, "{{alias}}"))
p.append(stat("⏱️ Uptime", 0, 13, 12, 5, UPTIME, "{{alias}}", unit="s",
              colorMode="value", textMode="value_and_name", steps=[{"value": None, "color": "blue"}]))
p.append(timeseries("📈 Load average (1m)", 12, 13, 12, 5, [tgt(LOAD, "{{alias}}")], unit="short"))
dashboards["fleet-command-bridge"] = dashboard(
    "fleet-command-bridge", "⚓ Fleet Command Bridge", ["fleet", "homelab"], p)

# 2) Resource Leaderboard
_pid[0] = 0
p = []
p.append(bargauge("⚙️ CPU load ranking", 0, 0, 12, 8, CPU, "{{alias}}"))
p.append(bargauge("🧠 Memory used ranking", 12, 0, 12, 8, RAM, "{{alias}}"))
p.append(bargauge("💾 Root disk used ranking", 0, 8, 12, 8, DISK, "{{alias}}"))
p.append(bargauge("🌊 Network throughput ranking", 12, 8, 12, 8, NET_TOT, "{{alias}}",
                  unit="Bps", mx=None, steps=[{"value": None, "color": "blue"}]))
dashboards["fleet-leaderboard"] = dashboard(
    "fleet-leaderboard", "🏴‍☠️ Resource Leaderboard", ["fleet", "homelab"], p)

# 3) The Hold (Storage)
_pid[0] = 0
FS_USED = (f'100 * (1 - node_filesystem_avail_bytes{{fstype=~"ext4|vfat",mountpoint=~"/|/boot",{F}}} '
           f'/ node_filesystem_size_bytes{{fstype=~"ext4|vfat",mountpoint=~"/|/boot",{F}}})')
FS_FREE = f'node_filesystem_avail_bytes{{mountpoint="/",fstype="ext4",{F}}}'
FS_PRED = f'predict_linear(node_filesystem_avail_bytes{{mountpoint="/",fstype="ext4",{F}}}[6h], 7*24*3600)'
p = []
p.append(bargauge("🗄️ Filesystem fill", 0, 0, 24, 8, FS_USED, "{{alias}} {{mountpoint}}"))
p.append(timeseries("📉 Free space on / (live)", 0, 8, 12, 8, [tgt(FS_FREE, "{{alias}}")], unit="bytes"))
p.append(stat("🔮 Projected free in 7 days", 12, 8, 12, 8, FS_PRED, "{{alias}}",
              unit="bytes", colorMode="value", textMode="value_and_name",
              steps=[{"value": None, "color": "purple"}]))
dashboards["fleet-storage"] = dashboard(
    "fleet-storage", "🗄️ The Hold — Storage", ["fleet", "homelab"], p)

# 4) Currents (Network)
_pid[0] = 0
p = []
p.append(stat("🌊 Total fleet throughput (in + out)", 0, 0, 24, 5, NET_TOT, "{{alias}}",
              unit="Bps", colorMode="value", graphMode="area", textMode="value_and_name",
              steps=[{"value": None, "color": "blue"}], instant=False))
p.append(timeseries("⬇️ Inbound (receive)", 0, 5, 12, 9, [tgt(NET_RX, "{{alias}}")], unit="Bps", fillOpacity=20))
p.append(timeseries("⬆️ Outbound (transmit)", 12, 5, 12, 9, [tgt(NET_TX, "{{alias}}")], unit="Bps", fillOpacity=20))
dashboards["fleet-network"] = dashboard(
    "fleet-network", "🌊 Currents — Network", ["fleet", "homelab"], p)

# 5) Engine Room (Thermals)
_pid[0] = 0
p = []
p.append(gauge("🌡️ Hottest sensor per ship", 0, 0, 24, 8, TEMP, "{{alias}}",
               unit="celsius", mx=100, steps=TEMP_STEPS))
p.append(timeseries("🔥 Temperature over time", 0, 8, 24, 9, [tgt(TEMP, "{{alias}}")],
                    unit="celsius", steps=TEMP_STEPS))
dashboards["fleet-thermals"] = dashboard(
    "fleet-thermals", "🌡️ Engine Room — Thermals", ["fleet", "homelab"], p)

# --- write + validate ---
for name, d in dashboards.items():
    path = os.path.join(OUT, name + ".json")
    with open(path, "w") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
    json.load(open(path))
    print(f"  wrote + validated {name}.json ({len(d['panels'])} panels)")
print("OK")
