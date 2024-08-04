# IPMI Exporter Setup with VictoriaMetrics and Grafana

This README guide explains how to set up and use the IPMI Exporter with VictoriaMetrics and Grafana for monitoring IPMI-enabled devices.

## Setting up IPMI Exporter

• Create an `ipmi_exporter` directory on the machine that will act as the exporter (this machine should have access to all IPMI devices):
   ```
   mkdir ipmi_exporter
   cd ipmi_exporter
   ```

• Create a `docker-compose.yml` file in this directory with the following content:

```yaml
---
services:
  ipmi_exporter:
    image: prometheuscommunity/ipmi-exporter:latest
    container_name: ipmi_exporter
    hostname: ipmi-exporter
    restart: unless-stopped
    command: --config.file /config.yml
    ports:
      - 9290:9290
    volumes:
      - ./ipmi_remote.yml:/config.yml:ro
    networks:
      - default
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:9290/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  default:
```

• Create an `ipmi_remote.yml` file in the same directory with the following content:

```yaml
modules:
  default:
    user: "ADMIN"
    pass: "KEAOISNQJB"
    driver: "LAN_2_0"
    privilege: "admin"
    timeout: 10000
    collectors:
    - bmc
    - ipmi
    - chassis
    - dcmi
    - sel
    - sel-events
    - sm-lan-mode
```

• Pull the Docker images and start the containers:
   ```
   docker compose pull
   docker compose up -d
   ```

• Test if the exporter is working correctly using curl:
   ```
   curl -Ss "http://10.255.255.36:9290/ipmi?module=default&target=10.255.255.19"
   ```
   Replace `10.255.255.36` with the IP of your exporter machine and `10.255.255.19` with the IP of an IPMI device. Note that the target IP doesn't need to be accessible from the machine running the curl command, but it must be accessible from the exporter machine.

## Configuring VictoriaMetrics

• Add the following job to your `scrape.yml` file in VictoriaMetrics:

```yaml
- job_name: ipmi_exporter
  params:
    module: ['default']
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /ipmi
  scheme: http
  file_sd_configs:
    - files:
        - /etc/prometheus/ipmi_targets.yml
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
      replacement: ${1}
    - source_labels: [__param_target]
      target_label: instance
      replacement: ${1}
    - target_label: __address__
      replacement: ipmi_exporter:9290
```

• Create an `ipmi_targets.yml` file at the root of your VictoriaMetrics Docker setup with the following content:

```yaml
- targets:
  - 10.255.255.19
  - 10.255.255.20
  - 10.255.255.21
  labels:
    job: ipmi_exporter
```

Add all the IP addresses of your IPMI devices to this file.

• Add a new volume to the `vmagent` service in your `docker-compose.yml`:

```yaml
volumes:
  - /srv/dockers/web/victoriametrics/ipmi_targets.yml:/etc/prometheus/ipmi_targets.yml
```

• Restart the VictoriaMetrics services:

```
docker compose down -v && docker compose up -d
```

## Setting up Grafana Dashboard

• Import the `grafana_dashboard.json` file into Grafana.
• Select the appropriate data source when importing the dashboard.
• Enjoy your new IPMI monitoring dashboard!

## Troubleshooting

If you encounter issues:

• Check that the IPMI Exporter is running and accessible:
  ```
  docker ps | grep ipmi_exporter
  curl -Ss "http://localhost:9290/metrics"
  ```

• Verify that the target IPMI devices are reachable from the exporter machine:
  ```
  ping <ipmi_device_ip>
  ```

• Check VictoriaMetrics logs for any scraping errors:
  ```
  docker logs <victoriametrics_container_name>
  ```

• Ensure that the `ipmi_targets.yml` file is correctly formatted and contains the right IP addresses.

• Verify that the Grafana data source is correctly configured to point to your VictoriaMetrics instance.

## References

• [IPMI Exporter GitHub Repository](https://github.com/prometheus-community/ipmi_exporter)
• [Grafana IPMI Exporter Dashboard](https://grafana.com/grafana/dashboards/15765-ipmi-exporter/)

For more detailed information and advanced configurations, please refer to the official documentation in the links provided above.