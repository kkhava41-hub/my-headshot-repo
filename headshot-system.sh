#!/bin/bash

#################################################################
#                                                               #
#   HEADSHOT MANAGEMENT SYSTEM - SHELL SCRIPT                  #
#   Complete System with all modules integration               #
#   Version: 2.0.0                                             #
#                                                               #
#################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables
PYTHON_CMD="python3"
SCRIPT_VERSION="2.0.0"
APP_NAME="Headshot Management System"

# ==================== FUNCTIONS ====================

# Clear screen and print header
print_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       📸 HEADSHOT MANAGEMENT SYSTEM 📸                         ║"
    echo "║       Professional Headshot Gallery Management v${SCRIPT_VERSION}            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print success message
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print error message
error() {
    echo -e "${RED}✗ $1${NC}"
}

# Print info message
info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Print warning message
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check Python installation
check_python() {
    if ! command -v $PYTHON_CMD &> /dev/null; then
        error "Python3 is not installed!"
        info "Please install Python3 and try again"
        exit 1
    fi
}

# Check required modules
check_modules() {
    print_header
    echo -e "${CYAN}Checking required modules...${NC}\n"
    
    modules=("headshot.ff" "utils.ff" "database.ff" "validator.ff" "exporter.ff")
    missing=0
    
    for module in "${modules[@]}"; do
        if [ -f "$module" ]; then
            success "Found: $module"
        else
            error "Missing: $module"
            missing=$((missing + 1))
        fi
    done
    
    echo ""
    
    if [ $missing -gt 0 ]; then
        warning "Some modules are missing. Some features may not work."
        read -p "Continue anyway? (y/n): " continue_choice
        if [ "$continue_choice" != "y" ]; then
            exit 1
        fi
    else
        success "All modules found!"
    fi
    
    sleep 2
}

# Main Menu
show_menu() {
    print_header
    
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                      MAIN MENU${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${GREEN}DATA MANAGEMENT:${NC}"
    echo "  1.  Add New Headshot"
    echo "  2.  View All Headshots"
    echo "  3.  Search Headshot (by name/email)"
    echo "  4.  Update Headshot"
    echo "  5.  Delete Headshot"
    echo ""
    
    echo -e "${GREEN}GALLERY:${NC}"
    echo "  6.  Create New Gallery"
    echo "  7.  Add to Gallery"
    echo "  8.  View Gallery"
    echo ""
    
    echo -e "${GREEN}EXPORT & REPORT:${NC}"
    echo "  9.  Export to JSON"
    echo "  10. Export to CSV"
    echo "  11. Export to HTML"
    echo "  12. Export to TXT"
    echo ""
    
    echo -e "${GREEN}SYSTEM:${NC}"
    echo "  13. View Statistics"
    echo "  14. Initialize Database"
    echo "  15. Create ZIP Archive"
    echo "  16. View Logs"
    echo "  17. System Info"
    echo ""
    
    echo -e "${GREEN}EXIT:${NC}"
    echo "  0.  Exit Application"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"
}

# Add new headshot
add_headshot() {
    print_header
    echo -e "${CYAN}ADD NEW HEADSHOT${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    read -p "Enter full name: " name
    read -p "Enter image path (e.g., /images/photo.jpg): " image_path
    read -p "Enter job title: " title
    read -p "Enter short bio: " bio
    read -p "Enter email address: " email
    read -p "Enter phone number: " phone
    
    echo ""
    info "Processing data..."
    
    $PYTHON_CMD << EOF
from utils import Headshot, HeadshotGallery
from validator import Validator
from utils import Logger

logger = Logger()

# Validate data
is_valid, errors = Validator.validate_headshot_data('$name', '$image_path', '$title', '$bio', '$email', '$phone')

if is_valid:
    hs = Headshot('$name', '$image_path', '$title', '$bio', '$email', '$phone')
    print("✓ Headshot created successfully!")
    print(f"  Name: {hs.name}")
    print(f"  Email: {hs.email}")
    print(f"  Title: {hs.title}")
    logger.success("Headshot added: $name")
else:
    print("✗ Validation failed!")
    for field, error in errors.items():
        print(f"  - {field}: {error}")
    logger.error("Validation failed for: $name")

EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# View all headshots
view_all() {
    print_header
    echo -e "${CYAN}ALL HEADSHOTS${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    $PYTHON_CMD << 'EOF'
from utils import Headshot, HeadshotGallery

gallery = HeadshotGallery("Sample Gallery")

# Sample data untuk demo
sample_headshots = [
    Headshot("John Doe", "/images/john.jpg", "Senior Engineer", "Full-stack developer", "john@company.com", "+1-555-0101"),
    Headshot("Jane Smith", "/images/jane.jpg", "Product Manager", "Product strategy", "jane@company.com", "+1-555-0102"),
    Headshot("Mike Johnson", "/images/mike.jpg", "UX Designer", "User experience", "mike@company.com", "+1-555-0103"),
]

for hs in sample_headshots:
    gallery.add_headshot(hs)

gallery.list_all()

EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# Export to JSON
export_json() {
    print_header
    echo -e "${CYAN}EXPORT TO JSON${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    read -p "Enter output filename (default: gallery.json): " filename
    filename=${filename:-gallery.json}
    
    info "Creating JSON export..."
    
    $PYTHON_CMD << EOF
from utils import Headshot, HeadshotGallery
import json

gallery = HeadshotGallery("Team Gallery")

# Sample data
sample_headshots = [
    Headshot("John Doe", "/images/john.jpg", "Senior Engineer", "Full-stack developer", "john@company.com", "+1-555-0101"),
    Headshot("Jane Smith", "/images/jane.jpg", "Product Manager", "Product strategy", "jane@company.com", "+1-555-0102"),
]

for hs in sample_headshots:
    gallery.add_headshot(hs)

gallery.export_to_json('$filename')

EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# Export to HTML
export_html() {
    print_header
    echo -e "${CYAN}EXPORT TO HTML${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    read -p "Enter output filename (default: gallery.html): " filename
    filename=${filename:-gallery.html}
    
    info "Creating HTML gallery..."
    
    $PYTHON_CMD << EOF
from utils import Headshot, HeadshotGallery

gallery = HeadshotGallery("Team Gallery")

# Sample data
sample_headshots = [
    Headshot("John Doe", "/images/john.jpg", "Senior Engineer", "Full-stack developer", "john@company.com", "+1-555-0101"),
    Headshot("Jane Smith", "/images/jane.jpg", "Product Manager", "Product strategy", "jane@company.com", "+1-555-0102"),
    Headshot("Mike Johnson", "/images/mike.jpg", "UX Designer", "User experience", "mike@company.com", "+1-555-0103"),
]

for hs in sample_headshots:
    gallery.add_headshot(hs)

gallery.generate_html_gallery('$filename')

EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# View Statistics
view_stats() {
    print_header
    echo -e "${CYAN}SYSTEM STATISTICS${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    $PYTHON_CMD << 'EOF'
from utils import Config
from datetime import datetime
import os

config = Config()

print("Application Name:", config.get("app_name"))
print("Version:", config.get("version"))
print("Database:", config.get("db_name"))
print("Default Gallery:", config.get("default_gallery"))
print("Export Formats:", ", ".join(config.get("export_formats")))
print("Current Time:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
print()
print("Files in current directory:")

files = [f for f in os.listdir('.') if f.endswith(('.ff', '.py', '.sh', '.json', '.html'))]
for f in files[:10]:
    size = os.path.getsize(f) / 1024
    print(f"  - {f} ({size:.2f} KB)")

EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# System Info
system_info() {
    print_header
    echo -e "${CYAN}SYSTEM INFORMATION${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    info "Application Name: $APP_NAME"
    info "Version: $SCRIPT_VERSION"
    echo ""
    
    info "Python Version:"
    $PYTHON_CMD --version
    echo ""
    
    info "System Info:"
    uname -a
    echo ""
    
    info "Current Directory:"
    pwd
    echo ""
    
    info "Files in Repository:"
    ls -lh *.ff *.py *.sh 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    
    read -p "Press Enter to continue..."
}

# Create ZIP Archive
create_zip() {
    print_header
    echo -e "${CYAN}CREATE ZIP ARCHIVE${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    info "Creating ZIP archive..."
    
    $PYTHON_CMD << 'EOF'
import zipfile
import os
from datetime import datetime

zip_filename = f"my-headshot-repo-{datetime.now().strftime('%Y%m%d_%H%M%S')}.zip"

files_to_zip = [
    'headshot.ff', 'database.ff', 'validator.ff', 'exporter.ff', 'utils.ff',
    'headshot.sh', 'zip_creator.py'
]

try:
    with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file in files_to_zip:
            if os.path.exists(file):
                zipf.write(file)
                print(f"  ✓ Added: {file}")
    
    zip_size = os.path.getsize(zip_filename) / (1024 * 1024)
    print(f"\n✓ ZIP file created: {zip_filename}")
    print(f"  Size: {zip_size:.2f} MB")
    print(f"  Location: {os.path.abspath(zip_filename)}")
    
except Exception as e:
    print(f"✗ Error creating ZIP: {e}")

EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# Initialize Database
init_database() {
    print_header
    echo -e "${CYAN}INITIALIZE DATABASE${NC}\n"
    echo "════════════════════════════════════════════════════════════════\n"
    
    info "Initializing database..."
    
    $PYTHON_CMD << 'EOF'
try:
    from database import Database
    db = Database("headshot.db")
    success_msg = "✓ Database initialized successfully!"
    print(success_msg)
    db.close()
except ImportError:
    print("⚠ Database module not available (demo mode)")
except Exception as e:
    print(f"✗ Error: {e}")

EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
main_loop() {
    while true; do
        show_menu
        read -p "Select option (0-17): " choice
        
        case $choice in
            1) add_headshot ;;
            2) view_all ;;
            3) info "Search feature will be implemented soon..."; read -p "Press Enter..."; ;;
            4) info "Update feature will be implemented soon..."; read -p "Press Enter..."; ;;
            5) info "Delete feature will be implemented soon..."; read -p "Press Enter..."; ;;
            6) info "Create gallery feature will be implemented soon..."; read -p "Press Enter..."; ;;
            7) info "Add to gallery feature will be implemented soon..."; read -p "Press Enter..."; ;;
            8) view_all ;;
            9) export_json ;;
            10) info "CSV export will be implemented soon..."; read -p "Press Enter..."; ;;
            11) export_html ;;
            12) info "TXT export will be implemented soon..."; read -p "Press Enter..."; ;;
            13) view_stats ;;
            14) init_database ;;
            15) create_zip ;;
            16) info "Logs feature will be implemented soon..."; read -p "Press Enter..."; ;;
            17) system_info ;;
            0)
                print_header
                echo -e "${GREEN}Thank you for using Headshot Management System!${NC}"
                echo -e "${BLUE}Goodbye! 👋${NC}\n"
                exit 0
                ;;
            *)
                error "Invalid option. Please select 0-17."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main entry point
main() {
    check_python
    check_modules
    main_loop
}

# Run application
main
