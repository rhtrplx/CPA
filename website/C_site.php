<?php


	class C_site{
		
		//==========attributs==========
		private $host= "10.194.196.26"; //localhost (127.0.0.1)
		private $user="admin";
		private $pass= "7891235"; //car on est sous linux, sous windows on doit retirer cette ligne car elle ne fera que des erreurs
		private $db="parcours_aerien"; //BDD pas table
		
		//==========méthode==========
	
	function effectuerRequete($requete){
		$ressource=false;
		$id_connexion=mysqli_connect($this->host,$this->user,$this->pass,$this->db);
		if ($id_connexion) 
		{
			$ressource=mysqli_query($id_connexion,$requete);
		}
		return $ressource;
	}
	
	
	
	
	//---connection---
	function Authentifier($pseudo,$pass){
		/*
			Code Retour de la méthode:
			0:	Authentification réussie
			1:  Utilisateur inexistant
			2:  Erreur de mot de passe
		*/	
		$code_retour=1;
		$table='Concurrents';
		$requete="SELECT `pass` FROM `$table` WHERE `pseudo`='$pseudo'";
		//echo "<b>Requete:</b> $requete<br />";
		$resultat=$this->effectuerRequete($requete);
		if ($resultat)
		{
			while ($tab=mysqli_fetch_array($resultat,MYSQLI_BOTH))
			{
				$mdp=$tab['pass'];
				//echo "<b>membre</b>: PSEUDO: $pseudo PASS: $pass<br />";
				if ($pass==$mdp) $code_retour=0;
				else $code_retour=2;
			}
		}
		//echo "RESULTAT:$code_retour<br />";
		return $code_retour;
	}
	
	public function afficherFormulaireConnexion(){
		?>
			<form method="POST" >
				<h2>Espace membres</h2><br />
				<div class="form-inline">
					<label for="ps">Login</label><br />
					<input type="text" name="pseudo" id="ps"><br />
				</div>
				<div class="form-inline">
					<label for="pwd">Mot de passe</label><br />
					<input type="password" name="pass" id="pwd"><br />
				</div>
				<input type="submit" value="Connecter"><br />
				<input type="hidden" name="valide" value="valide">
				<br />
				<h2>Pas encore inscrit?</h2>
				<a href="./inscription.php">Cliquez ici</a>
			</form>
		<?php
		
	}
	
	
	//---inscription---
	public function inscrireMembre($pseudo,$email){
		$table='t_membres';
		$requete="INSERT INTO $table (`IDConcurrents`, `Nom`, `Email`, `StatutInscription`) VALUES( '' , '" . $pseudo . "', '" . $email ."',0)";
		//echo "Requete: $requete<br />";
		$ressource=$this->effectuerRequete($requete);
		if (!$ressource) 
		{
			echo "<br>Erreur requete inscription membre.<br />";
			$error=1;
		}
		else
		{
			echo "Inscription réussie.<br />Veuillez vous connecter <a href='./index.php'>ici</a><br />";
			$error=0;
		}
		return $error;
	}
	
	
	public function afficherFormulairePreinscription(){
	?>
			<h2><b>Préinscription</b></h2><h4>Vous êtes sur le point de créer un compte qui vous permettra de vous authentifier.</h4><br />
			<form method="POST">
				Choisir un nom:<br />
				<input name="Nom" id="Nom" />
				<input type="button" value="Tester" onClick="location.href='./inscription.php?Nom='+document.getElementById('Nom').value; ">
				<?php
					if (isset($_GET['Nom']) AND !empty($_GET['Nom']) )
					{
						$test=$this->testerLogin($_GET['Nom']);
						if ($test==1) echo '<span class="KO"><b>Nom indisponible</b></span>';
						else echo '<span class="OK"><b>Tout est bon !</b></span>';
					}
				?>
				<br />
				Email <font color="red">valide</font>:</b><br />
				<input type="text" name="email"><br />
				<input type="submit" value="S'inscrire"><br />
				<input type="hidden" name="valide" value="valide">
				<?php 
				$ressource=$this->inscrireMembre($pseudo,$email);
				
				?>
				
			</form>
		<?php	
		
	}
	
	
	public function testerLogin($pseudo){
		$table='t_membres';
		$requete="SELECT COUNT(*) AS `nb` FROM `$table` WHERE pseudo='$pseudo'";
		//echo "<b>Requete:</b> $requete<br />";
		$resultat=$this->effectuerRequete($requete);
		if ($resultat){
			while ($tab=mysqli_fetch_array($resultat))
			{
				$nb=$tab['nb'];
			}
		}
		return $nb;
	}
	
	
	
	
	
	
	
	
	
}
