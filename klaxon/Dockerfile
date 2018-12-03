FROM axioscode/klaxon

RUN apt-get update && apt-get install -y --no-install-recommends cron && update-rc.d cron defaults
RUN echo "*/10 * * * * rake check:all" | crontab -
