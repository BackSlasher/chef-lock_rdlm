# Tests the server

execute 'service rdlm status' # Should exit with 0

bash 'test-rdlm' do
  code <<-EOT
  set -e
  PORT=#{node['mutex_identity']['port']}
  # Get lock
  echo get lock
  RAW_LOCK=$(curl -f -d '{"title": "client", "wait": 5, "lifetime": 300}' http://localhost:$PORT/locks/testy -si)
  echo extract lock url
  LOCK_URL=$(echo "$RAW_LOCK" | perl -ne 'print $1 if /^Location: ((\\w|\\/|:)+)(.*)/')
  # Fail to get another lock
  echo failing another lock
  if curl -sI -f -d '{"title": "different client", "wait": 5, "lifetime": 300}' http://localhost:$PORT/locks/testy; then
    echo 'got another lock. Bad'
    exit 1
  fi
  # Delete lock
  echo delete lock
  curl -f -X DELETE "$LOCK_URL"
  # Fail to delete again
  echo failing to re-delete lock
  if curl -f -X DELETE "$LOCK_URL"; then
    echo 'managed to delete same lock twice. Bad'
    exit 2
  fi
  EOT
end
