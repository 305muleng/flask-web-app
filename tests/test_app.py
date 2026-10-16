import pytest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app import app  # noqa: E402


class TestFlaskApp:
    def setup_class(self):
        app.config['TESTING'] = True
        self.client = app.test_client()

    def test_hello_world(self):
        response = self.client.get('/')
        assert response.status_code == 200
        assert response.data.decode('utf-8') == 'Hello, CI/CD with Jenkins!'


if __name__ == '__main__':
    pytest.main(['-v', __file__])
