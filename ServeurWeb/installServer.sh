#!/bin/bash

# 1. Update and install packages
apt update
apt install -y apache2 php libapache2-mod-php mariadb-server php-mysql

# 2. Start and enable services
systemctl start apache2
systemctl enable apache2
systemctl start mariadb
systemctl enable mariadb

# 3. Secure MariaDB (set root password to 'rootpass' for demo)
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'rootpass';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# 4. Create database and table, insert sample data
mysql -u root -prootpass <<EOF
CREATE DATABASE IF NOT EXISTS demo;
USE demo;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL
);
INSERT INTO users (name, job_title, department, email) VALUES
    ('Alice', 'Responsable RH', 'Ressources Humaines', 'alice@fake.com'),
    ('Bob', 'Développeur Web', 'Informatique', 'bob@fake.com'),
    ('Charlie', 'Analyste Sécurité', 'Sécurité', 'charlie@fake.com'),
    ('David', 'Chef de projet', 'Gestion de projet', 'david@fake.com'),
    ('Emma', 'Ingénieure Réseau', 'Infrastructure', 'emma@fake.com'),
    ('Fatima', 'Technicienne Support', 'Support', 'fatima@fake.com'),
    ('Georges', 'CEO', 'Administration', 'georges@fake.com'),
    ('Hugo', 'Comptable', 'Finance', 'hugo@fake.com'),
    ('Isabelle', 'Consultante Cybersécurité', 'Sécurité', 'isabelle@fake.com'),
    ('Julien', 'Data Scientist', 'Data', 'julien@fake.com'),
    ('Laura', 'Juriste', 'Juridique', 'laura@fake.com'),
    ('Nina', 'Chargée de communication', 'Communication', 'nina@fake.com');
EOF

# 5. Create vulnerable PHP website (shows all usernames if SQLi is successful)
cat <<'EOPHP' > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head><title>Employee Lookup</title></head>
<body>
<h2>Recherche d'employé</h2>
<form method="GET">
    Nom: <input type="text" name="name">
    <input type="submit" value="Rechercher">
</form>
<?php
if (isset($_GET['name'])) {
    $conn = new mysqli('localhost', 'root', 'rootpass', 'demo');
    if ($conn->connect_error) die("Connection failed");
    $name = $_GET['name'];
    // VULNERABLE TO SQL INJECTION!
    $sql = "SELECT * FROM users WHERE name = '$name'";
    $result = $conn->query($sql);
    if ($result && $result->num_rows > 0) {
        echo "<h3>Employés trouvés :</h3><ul>";
        while ($row = $result->fetch_assoc()) {
            echo "<li>Nom : " . htmlspecialchars($row['name']) . "<br>";
            echo "Poste : " . htmlspecialchars($row['job_title']) . "<br>";
            echo "Département : " . htmlspecialchars($row['department']) . "<br>";
            echo "Email : " . htmlspecialchars($row['email']) . "</li><br><br>";
        }
        echo "</ul>";
    } else {
        echo "Aucun employé trouvé.";
    }
    $conn->close();
}
?>
</body>
</html>
EOPHP

# 6. Set permissions and restart Apache
chown www-data:www-data /var/www/html/index.php
systemctl restart apache2

# 7. Download an image to root's home directory
wget -O /root/me.jpg https://elyesmanai.github.io/images/me.jpg
for i in {1..100}; do cat /root/me.jpg >> /root/next_prime_minister_of_canada.jpg; done

IP=$(hostname -I | awk '{print $1}')
echo "Setup complete. Visit http://$IP/index.php to test the vulnerable site."




# Partie de script pour créer un utilisateur Debian 'bob' avec un mot de passe faible et activer l'accès SSH

# 1. Créer l'utilisateur 'bob' avec dossier personnel
useradd -m bob

# 2. Définir un mot de passe faible (exemple : "password")
echo 'bob:password' | chpasswd

# 3. S'assurer que le service SSH est installé et démarré
apt update
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# 4. Installer gcc si nécessaire
apt install -y gcc

# 5. Configurer sudoers pour que bob puisse utiliser uniquement gcc avec sudo
if ! grep -q '^bob' /etc/sudoers; then
    echo 'bob ALL=(root) NOPASSWD: /usr/bin/gcc' >> /etc/sudoers
fi

# 6. Afficher un message de connexion
echo "L'utilisateur 'bob' a été créé avec le mot de passe 'password'."
echo "Il peut utiliser sudo uniquement sur gcc."
echo "Vous pouvez vous connecter via : ssh bob@$IP"
