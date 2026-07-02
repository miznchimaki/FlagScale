import os
import sys

def _log(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()

try:
    argv0 = sys.argv[0] if sys.argv else ""
    argv = " ".join(sys.argv)

    skip = False

    if argv0 == "-c":
        skip = True

    lower_argv = argv.lower()
    if any(x in lower_argv for x in ["conda", "pip", "setup.py", "easy_install"]):
        skip = True

    if os.environ.get("FLAGGEMS_DISABLE", "0") == "1":
        skip = True

    if not skip:
        import flag_gems

        mode = os.environ.get("FLAGGEMS_ENABLE_MODE", "all")
        ops = os.environ.get("FLAGGEMS_ONLY_OPS", "")

        if mode == "selective":
            include = [x.strip() for x in ops.split(",") if x.strip()]
            flag_gems.only_enable(include=include)
            _log(f"[FlagGems] selective enabled: {include}")
        else:
            flag_gems.enable()
            _log("[FlagGems] global enabled via sitecustomize.py")

except Exception as e:
    _log(f"[FlagGems] enable failed: {type(e).__name__}: {e}")
    if os.environ.get("FLAGGEMS_STRICT", "1") == "1":
        raise
