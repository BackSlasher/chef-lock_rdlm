# Tests the server

execute 'service rdlm-daemon status' # Should exit with 0

bash 'test-rdlm' do
  code <<-EOT
  set -e
  PORT=#{node['mutex_identity']['port']}
  # Get lock
  RAW_LOCK=$(curl -sI -f -d '{"title": "client", "wait": 5, "lifetime": 300}' http://localhost:7305/locks/testy)
  LOCK_URL=$(echo "$RAW_LOCK" | perl -ne 'print $1 if /^Location: (.*)$/')
  # Fail to get another lock
  if curl -sI -f -d '{"title": "different client", "wait": 5, "lifetime": 300}' http://localhost:7305/locks/testy; then
    echo 'got another lock. Bad'
    exit 1
  fi
  # Delete lock
  curl -f -x DELETE "$LOCK_URL"
  # Fail to delete again
  if curl -f -x DELETE "$LOCK_URL"; then
    echo 'managed to delete same lock twice. Bad'
    exit 2
  fi
  EOT
end
