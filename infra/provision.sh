sudo apt update
sudo apt -y upgrade
sudo apt install wget libssl-dev openssl make gcc zlib1g-dev -y

# Install Python
cd /opt
sudo wget https://www.python.org/ftp/python/3.9.2/Python-3.9.2.tgz
sudo tar xzvf Python-3.9.2.tgz

cd Python-3.9.2
./configure
make
sudo make install

sudo ln -fs /opt/Python-3.9.2/python /usr/bin/py
sudo ln -fs /opt/Python-3.9.2/python /usr/bin/python

# Install Pip
sudo apt install python3-pip
sudo ln -fs /usr/bin/pip3 /usr/bin/pip
sudo pip install --upgrade pip
sudo pip install wheel

# Virtual environment
cd /srv # Folder for user-specific stuff
sudo python -m venv airflow
cd airflow
source bin/activate

# Install Airflow
sudo /srv/airflow/bin/python -m pip install --upgrade pip # Latest pip version required otherwise __ctypes error
sudo apt install libffi-dev -y # Prevent ffi.h error
sudo apt install python3-setuptools
sudo adduser airflow --disabled-login --disabled-password --gecos "Airflow system user"
pip install "apache-airflow[celery,postgres,crypto]==2.2.3" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.2.3/constraints-3.9.txt"