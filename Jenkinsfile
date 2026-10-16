pipeline {
    agent {
        node {
            label ''
            customWorkspace 'D:/code/test/jenkins-workspace/flask-web-app'
        }
    }
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    environment {
        PYTHON_PATH = 'C:/Users/李德润/AppData/Local/Programs/Python/Python310/python.exe'
        PIP_CACHE_DIR = 'D:/code/test/cache/pip'
        TEMP = 'D:/code/test/temp'
        TMP = 'D:/code/test/temp'
        PYTHONUTF8 = '1'
        PYTHONIOENCODING = 'utf-8'
        GIT_CONFIG_COUNT = '1'
        GIT_CONFIG_KEY_0 = 'http.sslBackend'
        GIT_CONFIG_VALUE_0 = 'openssl'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Verify Python') {
            steps {
                bat 'if not exist "D:\\code\\test\\temp" mkdir "D:\\code\\test\\temp"'
                bat '"%PYTHON_PATH%" --version'
                bat 'if not exist .venv\\Scripts\\python.exe "%PYTHON_PATH%" -m venv .venv'
                bat '.venv\\Scripts\\python.exe -m pip --version'
            }
        }
        stage('Install Dependencies') {
            steps {
                bat '.venv\\Scripts\\python.exe -m pip install -r requirements-ci.txt'
            }
        }
        stage('Lint') {
            steps {
                bat '.venv\\Scripts\\python.exe -m flake8 app.py tests/'
            }
        }
        stage('Test') {
            steps {
                bat '.venv\\Scripts\\python.exe -m pytest tests/ -v --junitxml=reports/tests.xml --cov=app --cov-report=html --cov-report=term-missing'
            }
            post {
                always {
                    junit testResults: 'reports/tests.xml', allowEmptyResults: false
                    publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: true,
                        keepAll: true, reportDir: 'htmlcov', reportFiles: 'index.html',
                        reportName: 'Coverage Report'])
                }
            }
        }
        stage('Build') {
            steps {
                bat '.venv\\Scripts\\python.exe -m PyInstaller --noconfirm --onefile app.py'
                archiveArtifacts artifacts: 'dist/app.exe', fingerprint: true
            }
        }
        stage('Deploy') {
            steps {
                withEnv(['JENKINS_NODE_COOKIE=flask-web-app-service']) {
                    bat 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File ci\\deploy.ps1'
                }
            }
        }
    }
    post {
        success { echo 'CI/CD completed. Open http://localhost:5000/' }
        failure { echo 'CI/CD failed. Check the failed stage and console output.' }
    }
}
