// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require jquery_ujs
//= require popper
//= require tinymce
//= require bootstrap
//= require turbolinks
//= require_tree .

function editeur() {
    tinymce.init({
        selector: '#mytextarea',
        plugins: [
            'advlist autolink link image imagetools lists charmap print preview hr anchor pagebreak spellchecker',
            'searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking',
            'save table contextmenu directionality emoticons template paste textcolor'
        ],
        images_upload_url: '/uploadimage',
        automatic_uploads: true
    });
}

function afficheCarte(champ, fichier, depart, arrivee) {
    var mymap = L.map(champ);
    var hikebikemapUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';//version 2
    var hikebikemapAttribution = 'Map Data © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
    var hikebikemap = new L.TileLayer(hikebikemapUrl, {maxZoom: 17, attribution: hikebikemapAttribution});
    hikebikemap.addTo(mymap);
    var customLayer = L.geoJson(null, {
        // http://leafletjs.com/reference.html#geojson-style
        style: function(feature) {
            return { color: '#f00' };
        }
    });
    var runLayer = omnivore.gpx(fichier, null, customLayer)
        .on('ready', function() {
            mymap.fitBounds(runLayer.getBounds());
        })
        .on('click', function() {
            $('#profilModal').modal('toggle'); })
        .addTo(mymap);
    if (depart !== '' && arrivee !== '') {
        var departIcon = L.icon({
            iconUrl: '/departS.png',
            iconSize: [40, 40],
            iconAnchor: [15, 37]
        });
        var arriveeIcon = L.icon({
            iconUrl: '/arriveeS.png',
            iconSize: [40, 40],
            iconAnchor: [36, 39]
        });
        L.marker([depart.split(",")[0], depart.split(",")[1]], {icon: departIcon})
            .addTo(mymap);
        L.marker([arrivee.split(",")[0], arrivee.split(",")[1]], {icon: arriveeIcon})
            .addTo(mymap);
    }
}

function changerep() {
    var dest = "/photos_number/" + $( "select#randonnee_repertoire_photos option:checked" ).val();
    $("a#bouton").attr("href", dest).click();
}

function afficheMap() {
    $("div#mapid").remove();
    var selection = $( 'select#randonnee_fichier_gpx option:checked' ).val();
    if (selection !== '') {
        $("div.mapid").html("<div id='mapid'></div>");
        var fichier = "/gpx/randos/" + selection;
        afficheCarte('mapid', fichier, '', '');
    }
}