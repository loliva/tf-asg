#!/bin/bash -xe
#scriptkiddie m00d
sudo yum update -y
sudo yum install httpd php nano -y 
sudo systemctl start httpd
sudo systemctl enable httpd
sudo cat <<EOF > /var/www/html/index.php
<head>
    <meta charset="UTF-8">
</head>
<body>
    <div class="container mt-5">
        <p> Nombre del Servidor: <?php \$eip = file_get_contents('http://169.254.169.254/latest/meta-data/public-hostname'); echo \$eip; ?></p>
        <p> Zona de disponibilidad: <?php \$eip = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone'); echo \$eip; ?></p>
    </div>
</body>
</html>
EOF

