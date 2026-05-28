from flask import Flask, request, render_template_string
import hashlib

app = Flask(__name__)

TEMPLATE = """<!DOCTYPE html>
<html>
<head>
  <title>rhhi-demo: Crypto Demo</title>
  <style>
    body { font-family: sans-serif; max-width: 800px; margin: 2rem auto; padding: 0 1rem; }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th, td { text-align: left; padding: 0.5rem; border: 1px solid #ddd; }
    th { background: #f4f4f4; }
    .error { color: #c00; font-style: italic; }
    input[type=text] { width: 60%; padding: 0.4rem; }
    button { padding: 0.4rem 1rem; }
  </style>
</head>
<body>
  <h1>rhhi-demo: Crypto Demo</h1>
  <form method="post">
    <input type="text" name="text" value="{{ text }}">
    <button type="submit">Hash</button>
  </form>
  <table>
    <tr><th>Algorithm</th><th>Result</th></tr>
    {% for algo, result in results.items() %}
    <tr>
      <td>{{ algo }}</td>
      <td {% if result.startswith('ERROR') %}class="error"{% endif %}>{{ result }}</td>
    </tr>
    {% endfor %}
  </table>
</body>
</html>"""


@app.route("/")
def index():
    return '<h1>rhhi-demo</h1><p>Flask on Red Hat Hardened Python. Visit <a href="/crypto-demo">/crypto-demo</a>.</p>'


@app.route("/crypto-demo", methods=["GET", "POST"])
def crypto_demo():
    text = request.form.get("text", "Hello, RHEL!")
    results = {}
    for algo in ["md5", "sha256", "sha512"]:
        try:
            results[algo.upper()] = hashlib.new(algo, text.encode()).hexdigest()
        except ValueError as e:
            results[algo.upper()] = f"ERROR: {e}"
    return render_template_string(TEMPLATE, text=text, results=results)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
