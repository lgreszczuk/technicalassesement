from flask import Flask, request, render_template  # Import Flask and related modules
import mysql.connector  # Import MySQL connector for database interaction
import os  # Import os module to access environment variables

# Initialize the Flask application
app = Flask(__name__)

# Function to initialize the database table
def init_db():
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            database=os.getenv("DB_NAME")
        )
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL
            )
        """)
        conn.commit()
        cursor.close()
        conn.close()
        print("✅ Table 'users' ensured in database.")
    except Exception as e:
        print("❌ Database initialization failed:", e)
        
# Call database initialization before handling routes
init_db()

# Define the route for the root URL and allow both GET and POST methods
@app.route("/", methods=["GET", "POST"])
def index():
    # Establish a connection to the MySQL database using environment variables
    conn = mysql.connector.connect(
        host=os.getenv("DB_HOST"),  # Database host
        user=os.getenv("DB_USER"),  # Database user
        password=os.getenv("DB_PASS"),  # Database password
        database=os.getenv("DB_NAME")  # Database name
    )
    cursor = conn.cursor()  # Create a cursor object to execute SQL queries

    # Check if the request method is POST (form submission)
    if request.method == "POST":
        # Get the 'name' value from the submitted form
        name = request.form.get("name")
        # Insert the submitted name into the 'users' table
        cursor.execute("INSERT INTO users (name) VALUES (%s)", (name,))
        conn.commit()  # Commit the transaction to save changes

    # Retrieve all rows from the 'users' table
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()  # Fetch all rows as a list of tuples

    # Render the 'index.html' template and pass the 'users' data to it
    return render_template("index.html", users=users)

# Run the Flask application if this script is executed directly
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)  # Run on all available network interfaces at port 5000
