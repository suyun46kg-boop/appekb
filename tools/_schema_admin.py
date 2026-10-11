import os
import paramiko

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("139.100.232.15", username="root", password=os.environ["SSH_PASS"], timeout=20)
sql = r"""
\d public.carusel
\d public.recommendations
\d public.broadcasts
SELECT id, name, public FROM storage.buckets;
"""
sftp = c.open_sftp()
with sftp.file("/tmp/schema_admin.sql", "w") as f:
    f.write(sql)
sftp.close()
stdin, stdout, stderr = c.exec_command(
    "docker exec -i supabase-db psql -U postgres < /tmp/schema_admin.sql",
    timeout=60,
)
print(stdout.read().decode("utf-8", "replace"))
print(stderr.read().decode("utf-8", "replace"))
c.close()
