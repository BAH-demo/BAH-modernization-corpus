#!/bin/bash
# operationalize-django-oscar.sh
# Automated setup script to get Django Oscar running from the corpus
# Usage: bash operationalize-django-oscar.sh
#
# Prerequisites: Python 3.10+, Node.js 18+, pip, npm

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSCAR_DIR="$SCRIPT_DIR/modernization-corpus-aggregate/django-oscar"

echo "=========================================="
echo " Django Oscar - Operationalization Script"
echo "=========================================="
echo ""

# Step 1: Check prerequisites
echo "[1/7] Checking prerequisites..."
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required"; exit 1; }
command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1 || { echo "ERROR: pip is required"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js is required"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "ERROR: npm is required"; exit 1; }

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "  Python: $PYTHON_VERSION"
echo "  Node:   $(node --version)"
echo "  npm:    $(npm --version)"

# Step 2: Clone if not already present
if [ ! -d "$OSCAR_DIR" ]; then
    echo ""
    echo "[2/7] Cloning Django Oscar..."
    bash "$SCRIPT_DIR/CORPUS-AGGREGATION-SETUP.sh" django-oscar
else
    echo ""
    echo "[2/7] Django Oscar already cloned."
fi

# Step 3: Install Python dependencies
echo ""
echo "[3/7] Installing Python dependencies..."
cd "$OSCAR_DIR"
pip install -e ".[test]" --quiet 2>&1 | tail -3

# Step 4: Install and build frontend assets
echo ""
echo "[4/7] Building frontend assets..."
npm install --silent 2>&1 | tail -3
npm run build 2>&1 | tail -3

# Step 5: Set up database (SQLite)
echo ""
echo "[5/7] Setting up database..."
rm -f sandbox/db.sqlite
python sandbox/manage.py migrate --verbosity 0

# Step 6: Load fixture data
echo ""
echo "[6/7] Loading sample data (201 products, users, orders)..."
python sandbox/manage.py loaddata sandbox/fixtures/auth.json --verbosity 0
python sandbox/manage.py loaddata sandbox/fixtures/child_products.json --verbosity 0
python sandbox/manage.py oscar_import_catalogue sandbox/fixtures/*.csv 2>&1 | tail -2
python sandbox/manage.py oscar_import_catalogue_images sandbox/fixtures/images.tar.gz 2>&1 | tail -2
python sandbox/manage.py oscar_populate_countries --initial-only --verbosity 0
python sandbox/manage.py loaddata sandbox/fixtures/pages.json sandbox/fixtures/ranges.json sandbox/fixtures/offers.json --verbosity 0
python sandbox/manage.py loaddata sandbox/fixtures/orders.json --verbosity 0
python sandbox/manage.py clear_index --noinput --verbosity 0
python sandbox/manage.py update_index catalogue --verbosity 0
python sandbox/manage.py collectstatic --noinput --verbosity 0 2>&1 | tail -1

# Set a known password for the superuser
echo "from django.contrib.auth.models import User; u = User.objects.get(username='superuser'); u.set_password('testing123'); u.save()" | python sandbox/manage.py shell --verbosity 0 2>/dev/null

# Step 7: Start the server
echo ""
echo "[7/7] Starting Django Oscar..."
echo ""
echo "=========================================="
echo " Django Oscar is ready!"
echo "=========================================="
echo ""
echo "  Storefront: http://localhost:8000/en-gb/catalogue/"
echo "  Dashboard:  http://localhost:8000/en-gb/dashboard/"
echo "  Admin user: superuser / testing123"
echo ""
echo "  Press Ctrl+C to stop the server."
echo ""

python sandbox/manage.py runserver 0.0.0.0:8000
