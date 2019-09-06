echo "ALTER USER api_daemon WITH SUPERUSER;" | k exec sts/api-postgres-master -n fp -i -- /opt/bitnami/postgresql/bin/psql -U postgres 
