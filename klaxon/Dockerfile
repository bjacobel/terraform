FROM axioscode/klaxon

RUN apt-get update && apt-get install -y --no-install-recommends cron
RUN echo "*/10 * * * * rake check:all" | crontab -
