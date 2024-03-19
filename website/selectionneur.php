
<p>fichier du 19 mars, juste présentation</p>
    <div class="formbox">
        <form action="convertisseur.php" method="post" enctype="multipart/form-data" class="bloc">
            <h2>Fichier de suivi</h2>
            <label for="file" class="custom-file-input" id="GrosBouton">
                <span id="file-label">Sélectionner un fichier </span>
            </label>
            <input type="file" name="userfile" id="file" class="browse" style="display: none;">
            <br>
            <div class="select-container">
                <button class="select">Convertir</button>
            </div>
        </form>
        
    </div>
    <script>
    document.getElementById('file').addEventListener('change', function() {
        var fileName = this.value.split("\\").pop();
        document.getElementById('file-label').innerText = fileName;
        document.getElementById('file-label').classList.add('file-selected'); 
        document.getElementById("GrosBouton").style.backgroundColor = "green";
    });
</script>








