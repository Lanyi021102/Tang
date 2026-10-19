"""Offline integration test; synthetic responses, no database or paid model calls."""
import json
import os
from pathlib import Path
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
from urllib.parse import parse_qs, urlsplit

root = Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding="utf-8")
index = json.loads((root / "data/graph_entity_index.json").read_text(encoding="utf-8"))["entities"]
ids = {e["key"]: e["id"] for e in index}
a, b = ids["TC-FANG-0054"], ids["TC-FANG-0055"]
nodes = [{"id": a, "label": "光禄坊", "type": "Fang"}, {"id": b, "label": "殖业坊", "type": "Fang"}]
edges = [{"id": "relation-test", "source": b, "target": a, "type": "NORTH_OF", "label": "测试关系，非史实", "confidence": 1, "evidence_count": 1}]
evidence = [{"id": "chunk-test", "source_id": "source-test", "source_title": "模拟来源", "source_type": "test", "chapter": "测试卷", "page_start": 1, "original_text": "模拟史料原文，不代表真实历史"}]
seen = []

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_): pass

    def respond(self, body, status=200):
        self.send_response(status)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlsplit(self.path)
        seen.append(parsed.path)
        if parsed.path == "/invalid-json":
            self.respond(b"not-json"); return
        if parsed.path == "/api/v1/graph/neighbors":
            query = parse_qs(parsed.query)
            assert query["entity_id"][0] in (a, b)
            assert "NORTH_OF" in query["relation_types"]
            payload = {"nodes": nodes, "edges": edges, "meta": {"truncated": False}}
        elif parsed.path.startswith("/api/v1/research/"):
            payload = {"id": parsed.path.rsplit("/", 1)[-1], "name": "测试", "evidence": evidence, "source_name": "殖业坊", "target_name": "光禄坊", "type": "NORTH_OF"}
        else:
            self.respond(b"{}", 404); return
        self.respond(json.dumps(payload, ensure_ascii=False).encode())

    def do_POST(self):
        seen.append(self.path)
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        assert body["source_id"] == a and body["target_id"] == b
        assert body["max_depth"] == 3 and body["max_paths"] == 5
        self.respond(json.dumps({"paths": [{"nodes": nodes, "edges": edges, "length": 1}], "total": 1}).encode())

server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
Thread(target=server.serve_forever, daemon=True).start()
try:
    env = dict(os.environ, GRAPH_TEST_PORT=str(server.server_port))
    try:
        result = subprocess.run([sys.argv[1], "--headless", "--path", str(root), "--script", "tools/test_graph_cards.gd"], env=env, capture_output=True, timeout=20)
    except subprocess.TimeoutExpired as exc:
        print(((exc.stdout or b"") + (exc.stderr or b"")).decode("utf-8", errors="replace"))
        raise
    output = (result.stdout + result.stderr).decode("utf-8", errors="replace")
    print(output)
    assert result.returncode == 0 and "GRAPH_TEST_PASS" in output and "SCRIPT ERROR" not in output
    assert "/api/v1/graph/path" in seen
    assert "/api/v1/research/relations/relation-test" in seen
finally:
    server.shutdown()
    server.server_close()
