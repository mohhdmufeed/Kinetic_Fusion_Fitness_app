import http.server
import socketserver
import os
import mimetypes

PORT = 8080
DIRECTORY = r"c:\Users\mohdm\Downloads\wger-master\getfit_flutter\build\web"

mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/vnd.android.package-archive', '.apk')
mimetypes.add_type('application/json', '.json')

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, HEAD, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        if self.path.endswith('.apk'):
            self.send_header('Content-Disposition', 'attachment; filename="GetFit.apk"')
            self.send_header('Content-Type', 'application/vnd.android.package-archive')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.end_headers()

class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

if __name__ == '__main__':
    os.chdir(DIRECTORY)
    server = ThreadedHTTPServer(('0.0.0.0', PORT), CustomHandler)
    print(f"Serving GetFit on http://0.0.0.0:{PORT} from {DIRECTORY}")
    server.serve_forever()
