<?php
	if ( isset($_GET['page']) AND !empty($_GET['page']) ){
		$page = $_GET['page'];

		switch($page){
			case "accueil": include ('./accueil.php'); break;
			case "preinscription": include ('./preinscription.php'); break;
			case "camera": include ('./camera.php'); break;
			case "connectOrganisateur":include ('./connectOrganisateur.php'); break;
			case "déconnexion":include ('./disconnect.php'); break;
			case "selectionneur":include ('./selectionneur.php'); break;
			default:
				include ('./404.php');
		}
	}
	else include ('./404.php');
?>