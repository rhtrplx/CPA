<?php
	session_start();
?>

<!DOCTYPE html>
<html lang='fr'>
<head>
	<title>Course aérienne</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
    <link rel="stylesheet" type="text/css" href="./style.css" />
</head>
<body>
<!----------bannière / entête---------->
<div class="entete">
    <h1 class="titre">Course Aérienne</h1>
    <p>Obtenez la première place dans les blus beaux paysages du var</p>
    </div>
    <br /><br />

<!----------Corps de page---------->
<div class="row">
    <div class="column side">
        <div class="container mt-3">
            <?php include ('./menu.php');?>     
    </div></div>
    


    <div class="column middle">
        <?php 
            print_r($_SESSION); //efface-le quand tu pourras
            include ('./controleur.php'); 
        ?> 
    </div>


    <div class="column side">
        <h3>Dois-je rester ici ?</h3>
        <p>supprime cette barre de droite si inutile</p>
    </div>


    <!----------diep de page---------->
    <div class="credits">
    <h4>Site créé par Les derniers BTS SNIR de Lorgues</h4>
    <p>  // février-mai 2024</p>
    </div>

</div>
</body>
</html>
