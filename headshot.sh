#!/bin/bash

#################################################################
#                                                               #
#   HEADSHOT MANAGEMENT SYSTEM - MAIN SCRIPT                   #
#   Version: 1.0.0                                             #
#   Author: kkhava41-hub                                       #
#                                                               #
#################################################################

# Color codes untuk output yang lebih cantik
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_CMD="python3"
LOG_FILE="headshot.log"
DB_FILE="headshot.db"

# ==================== FUNCTIONS ====================

# Print header
print_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       📸 HEADSHOT MANAGEMENT SYSTEM 📸                         ║"
    echo "║       Professional Headshot Gallery Management                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Print info message
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check Python installation
check_python() {
    if ! command -v $PYTHON_CMD &> /dev/null; then
        print_error "Python3 is not installed!"
        print_info "Please install Python3 and try again"
        exit 1
    fi
    print_success "Python3 found: $($PYTHON_CMD --version)"
}

# Initialize database
init_database() {
    print_info "Initializing database..."
    $PYTHON_CMD << 'EOF'
from database import Database
db = Database()
print("Database initialized successfully")
db.close()
EOF
    if [ $? -eq 0 ]; then
        print_success "Database initialized"
    else
        print_error "Failed to initialize database"
    fi
}

# Show main menu
show_menu() {
    print_header
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                      MAIN MENU${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Add New Headshot"
    echo -e "${GREEN}2.${NC} View All Headshots"
    echo -e "${GREEN}3.${NC} Search Headshot"
    echo -e "${GREEN}4.${NC} Update Headshot"
    echo -e "${GREEN}5.${NC} Delete Headshot"
    echo -e "${GREEN}6.${NC} Create Gallery"
    echo -e "${GREEN}7.${NC} Export Gallery"
    echo -e "${GREEN}8.${NC} Generate HTML"
    echo -e "${GREEN}9.${NC} View Statistics"
    echo -e "${GREEN}10.${NC} View Logs"
    echo -e "${GREEN}0.${NC} Exit"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
}

# Add new headshot
add_headshot() {
    print_header
    echo -e "${CYAN}ADD NEW HEADSHOT${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    read -p "Enter name: " name
    read -p "Enter image path: " image_path
    read -p "Enter title: " title
    read -p "Enter bio: " bio
    read -p "Enter email: " email
    read -p "Enter phone: " phone
    
    $PYTHON_CMD << EOF
from database import Database
from validator import Validator

db = Database()
is_valid, errors = Validator.validate_headshot_data('$name', '$image_path', '$title', '$bio', '$email', '$phone')

if is_valid:
    result = db.insert_headshot('$name', '$image_path', '$title', '$bio', '$email', '$phone')
    if result:
        print("✓ Headshot added successfully (ID: {})".format(result))
    else:
        print("✗ Failed to add headshot")
else:
    print("✗ Validation errors:")
    for field, error in errors.items():
        print(f"  - {field}: {error}")

db.close()
EOF
    
    read -p "Press Enter to continue..."
}

# View all headshots
view_all() {
    print_header
    echo -e "${CYAN}ALL HEADSHOTS${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    $PYTHON_CMD << 'EOF'
from database import Database

db = Database()
headshots = db.get_all_headshots()

if headshots:
    print(f"Total Headshots: {len(headshots)}\n")
    for i, hs in enumerate(headshots, 1):
        print(f"{i}. {hs[1]} (ID: {hs[0]})")
        print(f"   Title: {hs[3]}")
        print(f"   Email: {hs[5]}")
        print(f"   Phone: {hs[6]}")
        print()
else:
    print("No headshots found")

db.close()
EOF
    
    read -p "Press Enter to continue..."
}

# Search headshot
search_headshot() {
    print_header
    echo -e "${CYAN}SEARCH HEADSHOT${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    read -p "Enter search keyword (name or email): " keyword
    
    $PYTHON_CMD << EOF
from database import Database

db = Database()
results = db.search_headshot('$keyword')

if results:
    print(f"Found {len(results)} result(s):\n")
    for hs in results:
        print(f"ID: {hs[0]}")
        print(f"Name: {hs[1]}")
        print(f"Title: {hs[3]}")
        print(f"Email: {hs[5]}")
        print(f"Phone: {hs[6]}")
        print("-" * 60)
else:
    print("No results found")

db.close()
EOF
    
    read -p "Press Enter to continue..."
}

# Generate HTML gallery
generate_html() {
    print_header
    echo -e "${CYAN}GENERATE HTML GALLERY${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    read -p "Enter output filename (default: gallery.html): " output_file
    output_file=${output_file:-gallery.html}
    
    $PYTHON_CMD << EOF
from database import Database
from exporter import Exporter

db = Database()
headshots = db.get_all_headshots()

if headshots:
    exporter = Exporter()
    exporter.export_to_html(headshots, '$output_file', 'Team Gallery')
    print(f"✓ HTML gallery generated: $output_file")
else:
    print("✗ No headshots to export")

db.close()
EOF
    
    read -p "Press Enter to continue..."
}

# Export gallery
export_gallery() {
    print_header
    echo -e "${CYAN}EXPORT GALLERY${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${GREEN}1.${NC} Export to JSON"
    echo -e "${GREEN}2.${NC} Export to CSV"
    echo -e "${GREEN}3.${NC} Export to TXT"
    echo -e "${GREEN}4.${NC} Export to HTML"
    echo ""
    
    read -p "Select export format (1-4): " export_choice
    
    case $export_choice in
        1)
            read -p "Enter filename (default: gallery.json): " filename
            filename=${filename:-gallery.json}
            $PYTHON_CMD << EOF
from database import Database
import json

db = Database()
headshots = db.get_all_headshots()

if headshots:
    data = {
        "total_headshots": len(headshots),
        "headshots": [
            {
                "id": hs[0],
                "name": hs[1],
                "title": hs[3],
                "email": hs[5],
                "phone": hs[6]
            }
            for hs in headshots
        ]
    }
    with open('$filename', 'w') as f:
        json.dump(data, f, indent=2)
    print("✓ Exported to $filename")
else:
    print("✗ No headshots to export")

db.close()
EOF
            ;;
        2)
            read -p "Enter filename (default: gallery.csv): " filename
            filename=${filename:-gallery.csv}
            $PYTHON_CMD << EOF
from database import Database
from exporter import Exporter

db = Database()
headshots = db.get_all_headshots()

if headshots:
    exporter = Exporter()
    exporter.export_to_csv(headshots, '$filename')
else:
    print("✗ No headshots to export")

db.close()
EOF
            ;;
        3)
            read -p "Enter filename (default: gallery.txt): " filename
            filename=${filename:-gallery.txt}
            $PYTHON_CMD << EOF
from database import Database
from exporter import Exporter

db = Database()
headshots = db.get_all_headshots()

if headshots:
    exporter = Exporter()
    exporter.export_to_txt(headshots, '$filename')
else:
    print("✗ No headshots to export")

db.close()
EOF
            ;;
        4)
            generate_html
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# View statistics
view_stats() {
    print_header
    echo -e "${CYAN}STATISTICS${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    $PYTHON_CMD << 'EOF'
from database import Database
from datetime import datetime

db = Database()
headshots = db.get_all_headshots()

print(f"Total Headshots: {len(headshots)}")
print(f"Database: headshot.db")
print(f"Current Time: {datetime.now().isoformat()}")
print()

# Count by title
if headshots:
    titles = {}
    for hs in headshots:
        title = hs[3] if hs[3] else "No Title"
        titles[title] = titles.get(title, 0) + 1
    
    print("Headshots by Title:")
    for title, count in titles.items():
        print(f"  - {title}: {count}")

db.close()
EOF
    
    read -p "Press Enter to continue..."
}

# View logs
view_logs() {
    print_header
    echo -e "${CYAN}APPLICATION LOGS${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    if [ -f "$LOG_FILE" ]; then
        tail -50 "$LOG_FILE"
    else
        print_warning "No log file found yet"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
main() {
    check_python
    
    while true; do
        show_menu
        read -p "Select option (0-10): " choice
        
        case $choice in
            1) add_headshot ;;
            2) view_all ;;
            3) search_headshot ;;
            4) 
                print_info "Update feature coming soon..."
                read -p "Press Enter to continue..."
                ;;
            5)
                print_info "Delete feature coming soon..."
                read -p "Press Enter to continue..."
                ;;
            6)
                print_info "Create gallery feature coming soon..."
                read -p "Press Enter to continue..."
                ;;
            7) export_gallery ;;
            8) generate_html ;;
            9) view_stats ;;
            10) view_logs ;;
            0)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function
main
