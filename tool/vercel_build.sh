#!/usr/bin/env bash
# Vercel build step. Runs in a separate shell from the install step,
# so PATH must be set again here.
set -euo pipefail

export PATH="/tmp/flutter/bin:$PATH"
flutter build web --release
