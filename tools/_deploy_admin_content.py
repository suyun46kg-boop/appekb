import os
import sys
from pathlib import Path

import paramiko

HOST = "139.100.232.15"
REMOTE_DIR = "/root/supabase/docker/volumes/functions/admin-content"
REMOTE_SHARED = "/root/supabase/docker/volumes/functions/_shared"
LOCAL_DIR = Path(__file__).resolve().parents[1] / "supabase" / "functions" / "admin-content"
LOCAL_SHARED = Path(__file__).resolve().parents[1] / "supabase" / "functions" / "_shared"


def main() -> int:
    password = os.environ.get("SSH_PASS")
    if not password:
        print("SSH_PASS is not set", file=sys.stderr)
        return 1

    index_local = LOCAL_DIR / "index.ts"
    if not index_local.is_file():
        print(f"missing {index_local}", file=sys.stderr)
        return 1

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, username="root", password=password, timeout=20)

    def run(cmd: str) -> str:
        _stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
        out = stdout.read().decode("utf-8", "replace")
        err = stderr.read().decode("utf-8", "replace")
        code = stdout.channel.recv_exit_status()
        if code != 0:
            raise RuntimeError(f"cmd failed ({code}): {cmd}\n{out}\n{err}")
        return out

    run(f"mkdir -p {REMOTE_DIR} {REMOTE_SHARED}")

    sftp = client.open_sftp()
    sftp.put(str(index_local), f"{REMOTE_DIR}/index.ts")
    for name in ("fcm.ts",):
        local = LOCAL_SHARED / name
        if local.is_file():
            sftp.put(str(local), f"{REMOTE_SHARED}/{name}")
    sftp.close()

    # Restart edge runtime so new function is picked up.
    restart_out = ""
    for service in ("supabase-edge-functions", "functions", "supabase-functions"):
        try:
            restart_out = run(f"docker restart {service}")
            print(f"restarted: {restart_out.strip()}")
            break
        except RuntimeError as exc:
            restart_out = str(exc)
    else:
        # Fallback: restart whatever container exposes edge functions.
        names = run("docker ps --format '{{.Names}}'")
        print("containers:", names)
        for line in names.splitlines():
            if "function" in line.lower() or "edge" in line.lower():
                print(run(f"docker restart {line.strip()}").strip())
                break

    listing = run(f"ls -la {REMOTE_DIR} && wc -l {REMOTE_DIR}/index.ts")
    print(listing)
    client.close()
    print("deploy ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
