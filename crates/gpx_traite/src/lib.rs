#[macro_use]
extern crate helix;
extern crate quick_xml;

#[macro_use]
extern crate serde_derive;
extern crate serde;
extern crate serde_json;

extern crate regex;

extern crate chrono;

use quick_xml::Reader;
use quick_xml::events::Event;
use std::fs;
use regex::Regex;

use chrono::DateTime;

#[derive(Debug, Copy, Clone)]
struct Point {
    lat: f64,
    lon: f64,
    ele: f64,
}
#[derive(Serialize, Deserialize, Debug)]
struct Resultat {
    heure_debut : String,
    heure_fin : String,
    lon_depart: f64,
    lat_depart: f64,
    lon_arrivee: f64,
    lat_arrivee: f64,
    altitude_mini : f64,
    altitude_maxi : f64,
    cumul_montee: f64,
    cumul_descente: f64,
    distance: f64,
    lat_min: f64,
    lat_max: f64,
    lon_min: f64,
    lon_max: f64,
    profil: Vec<Vec<[i32 ; 2]>>
}

#[derive(Serialize, Deserialize, Debug)]
struct ListeGpx {
    resultat : String,
    fichiers: Vec<String>
}

fn lit_trace(nom: &String) -> (String, String, Vec<Vec<Point>>, f64, f64, f64, f64) {
    let mut reader = Reader::from_file(nom).unwrap();
    reader.trim_text(true);

    let mut buf = Vec::new();
    let mut points= Vec::new();
    let mut points_trk = Vec::new();
    let mut point = Point { lon: 0f64, lat: 0f64, ele: 0f64 };
    let mut dans_trkpt = false;
    let mut dans_ele = false;
    let mut dans_time = false;
    let mut heure_debut = None;
    let mut heure_fin = "".to_string();
    let mut lat_min = 10_000.0;
    let mut lat_max = -10_000.0;
    let mut lon_min = 10_000.0;
    let mut lon_max = -10_000.0;

    loop {
        match reader.read_event(&mut buf) {
            Ok(Event::Start(ref e)) => {
                match e.name() {
                    b"trk" => {
                        points_trk = Vec::new();
                    }
                    b"trkpt" => {
                        dans_trkpt = true;
                        point = Point { lon: 0f64, lat: 0f64, ele: 0f64 };
                        for att in e.attributes() {
                            let item = att.unwrap();
                            let cle = item.key.to_vec();
                            let cle = String::from_utf8(cle).unwrap();
                            let valeur = item.value.to_vec();
                            let valeur = String::from_utf8(valeur).unwrap().parse().unwrap();
                            if cle == "lon" {
                                point.lon = valeur;
                                if valeur > lon_max {
                                    lon_max = valeur;
                                } else if valeur < lon_min {
                                    lon_min = valeur;
                                }
                            } else if cle == "lat" {
                                point.lat = valeur;
                                if valeur > lat_max {
                                    lat_max = valeur;
                                } else if valeur < lat_min {
                                    lat_min = valeur;
                                }
                            }
                        }
                    }
                    b"ele" => dans_ele = true,
                    b"time" => dans_time = true,
                    _ => (),
                }
            }
            // unescape and decode the text event using the reader encoding
            Ok(Event::End(ref e)) => {
                match e.name() {
                    b"ele" => dans_ele = false,
                    b"time" => dans_time = false,
                    b"trkpt" => {
                        dans_trkpt = false;
                        points_trk.push(point.clone());
                    }
                    b"trk" => {
                        points.push(points_trk.clone());
                    }
                    _ => (),
                }
            }
            Ok(Event::Text(e)) => {
                if dans_ele && dans_trkpt {
                    point.ele = e.unescape_and_decode(&reader).unwrap().parse().unwrap()
                } else if dans_time && dans_trkpt {
                    if heure_debut.is_none() {
                        heure_debut = Some(e.unescape_and_decode(&reader).unwrap())
                    };
                    heure_fin = e.unescape_and_decode(&reader).unwrap()
                }
            }
            Ok(Event::Eof) => break, // exits the loop when reaching end of file
            Err(e) => panic!("Error at position {}: {:?}", reader.buffer_position(), e),
            _ => (), // There are several other `Event`s we do not consider here
        }

        // if we don't keep a borrow elsewhere, we can clear the buffer to keep memory usage low
        buf.clear();
    }
    (heure_debut.unwrap(), heure_fin, points, lat_min, lat_max, lon_min, lon_max)
}

fn traite_altitudes(points: &Vec<Vec<Point>>) -> (f64, f64, f64, f64, Vec<Vec<f64>>) {
    let mut altitudes_lissees = Vec::new();
    let mut altitude_mini = 10_000f64;
    let mut altitude_maxi = -10_000f64;
    let mut cumul_montee = 0.0;
    let mut cumul_descente = 0.0;

    for points_trk in points {
        let mut altitudes_lissees_trk = Vec::new();
        let longueur = points_trk.len();
        if longueur > 5 {
            altitudes_lissees_trk.push(points_trk[0].ele);
            altitudes_lissees_trk.push(points_trk[1].ele);
            for i in 2..longueur - 2 {
                let a_moy = (points_trk[i - 2].ele
                    + points_trk[i - 1].ele
                    + points_trk[i].ele
                    + points_trk[i + 1].ele
                    + points_trk[i + 2].ele) / 5f64;
                altitudes_lissees_trk.push(a_moy);
            }
            altitudes_lissees_trk.push(points_trk[longueur - 2].ele);
            altitudes_lissees_trk.push(points_trk[longueur - 1].ele);
        } else {
            for i in 0..longueur - 1 {
                altitudes_lissees_trk.push(points_trk[i].ele)
            }
        };
        for i in 0..altitudes_lissees_trk.len() {
            let a = altitudes_lissees_trk[i];
            if a > altitude_maxi { altitude_maxi = a };
            if a < altitude_mini { altitude_mini = a };
        }
        for i in 1..altitudes_lissees_trk.len() {
            let diff = altitudes_lissees_trk[i] - altitudes_lissees_trk[i - 1];
            if diff < 0.0 {
                cumul_descente += -diff;
            } else {
                cumul_montee += diff;
            }
        }
        altitudes_lissees.push(altitudes_lissees_trk)
    }
    (altitude_mini, altitude_maxi, cumul_montee, cumul_descente, altitudes_lissees)
}

fn calcule_distance(p1_lat: f64, p1_lon: f64, p2_lat: f64, p2_lon: f64) -> f64 {
    let a = 6_378_137.0;
    let b = 6_356_752.314245;
    let f = 1.0 / 298.257223563;
    let l_maj = (p2_lon - p1_lon).to_radians();
    let u_maj1 = ((1.0 - f) * p1_lat.to_radians().tan()).atan();
    let u_maj2 = ((1.0 - f) * p2_lat.to_radians().tan()).atan();
    let sin_u_maj1 = u_maj1.sin();
    let cos_u_maj1 = u_maj1.cos();
    let sin_u_maj2 = u_maj2.sin();
    let cos_u_maj2 = u_maj2.cos();
    let cos_sq_alpha = 0.0;
    let mut sin_sigma;
    let cos2_sigma_m = 0.0;
    let mut cos_sigma ;
    let mut sigma ;
    let mut lambda = l_maj;
    let mut iter_limit = 100;
    loop {
        let sin_lambda = lambda.sin();
        let cos_lambda = lambda.cos();
        sin_sigma = ((cos_u_maj2 * sin_lambda) * (cos_u_maj2 *
            sin_lambda) + (cos_u_maj1 * sin_u_maj2 -
            sin_u_maj1 * cos_u_maj2 * cos_lambda) *
            (cos_u_maj1 * sin_u_maj2 - sin_u_maj1 *
                cos_u_maj2 * cos_lambda)).sqrt();
        if sin_sigma == 0.0 { return 0.0};
        cos_sigma = sin_u_maj1 * sin_u_maj2 + cos_u_maj1 * cos_u_maj2 * cos_lambda;
        sigma = sin_sigma.atan2(cos_sigma);
        let sin_alpha = cos_u_maj1 * cos_u_maj2 * sin_lambda / sin_sigma;
        let cos_sq_alpha = 1.0 - sin_alpha * sin_alpha;
        let cos2_sigma_m = cos_sigma - 2.0 * sin_u_maj1 * sin_u_maj2 / cos_sq_alpha;
        let c_maj = f / 16.0 * cos_sq_alpha * (4.0 + f * (4.0 - 3.0 * cos_sq_alpha));
        let lambda_p = lambda;
        lambda = l_maj + (1.0 - c_maj) * f * sin_alpha *
            (sigma + c_maj * sin_sigma * (cos2_sigma_m + c_maj *
                cos_sigma * (-1.0 + 2.0 * cos2_sigma_m * cos2_sigma_m)));
        iter_limit -= 1;
        if (lambda - lambda_p).abs() < 1e-12 || iter_limit <= 0 { break };
    }
    if iter_limit == 0 { return 0.0 };
    let u_sq = cos_sq_alpha * (a * a - b * b) / (b * b);
    let a_maj = 1.0 + u_sq / 16_384.0 * (4096.0 + u_sq *
        (-768.0 + u_sq * (320.0 - 175.0 * u_sq)));
    let b_maj = u_sq / 1024.0 * (256.0 + u_sq * (-128.0 + u_sq * (74.0 - 47.0 * u_sq)));
    let delta_sigma = b_maj * sin_sigma * (cos2_sigma_m + b_maj / 4.0 *
        (cos_sigma * (-1.0 + 2.0 * cos2_sigma_m * cos2_sigma_m) -
            b_maj / 6.0 * cos2_sigma_m * (-3.0 + 4.0 * sin_sigma *
                sin_sigma) * (-3.0 + 4.0 * cos2_sigma_m * cos2_sigma_m)));
    b * a_maj * (sigma - delta_sigma)
}

fn traite_distances(points: Vec<Vec<Point>>) -> Vec<Vec<f64>> {
    let mut distances_cumulees = Vec::new();
    let mut cumul = 0.0;
    for points_trk in points {
        let mut distances_cumulees_trk = Vec::new();
        distances_cumulees_trk.push(cumul);
        for i in 1..points_trk.len() {
            cumul += calcule_distance(points_trk[i - 1].lat, points_trk[i - 1].lon,
                                      points_trk[i].lat, points_trk[i].lon);
            distances_cumulees_trk.push(cumul);
        }
        distances_cumulees.push(distances_cumulees_trk);
    }
    distances_cumulees
}

fn construit_profil(altitudes_lissees: &Vec<Vec<f64>>, altitude_mini: f64, altitude_maxi: f64,
                    distances_cumulees: Vec<Vec<f64>>, distance: f64) -> Vec<Vec<[i32 ; 2]>> {
    let coef_x = 2000.0/distance;
    let coef_y = 1000.0/(altitude_maxi-altitude_mini);
    let mut profil = Vec::new();
    let mut itrk = 0;
    for altitudes_lissees_trk in altitudes_lissees {
        let mut profil_trk = Vec::new();
        for i in 0..altitudes_lissees_trk.len() {
            profil_trk.push([(distances_cumulees[itrk][i] * coef_x).round() as i32, (1000.0 - (altitudes_lissees_trk[i] - altitude_mini) * coef_y).round() as i32])
        };
        let mut profil_filtre_trk = Vec::new();
        let mut prec = [-1, -1];
        for el in profil_trk {
            if el != prec {
                profil_filtre_trk.push(el)
            }
            prec = el;
        };
        profil.push(profil_filtre_trk);
        itrk += 1;
    }
    profil
}

fn simplifie_resultat(fichier: String) -> String {
    //extraire les pistes
    let mut resultat = "".to_string();
    let re_track = Regex::new(r"(?s)^(.*?)(<trk>.*</trk>)(.*)$").unwrap();
    let cap1 = re_track.captures(&fichier).unwrap();
    let pistes = &cap1[2];
    resultat.push_str(&cap1[1]);
    let re_track = Regex::new(r"(?s)(<trk>.*?</trk>)").unwrap();
    let re_points = Regex::new(r"(?s)^(.*?)(<trkpt.*</trkpt>)(.*)$").unwrap();
    let re_point = Regex::new(r"(?s)(<trkpt.*?</trkpt>)").unwrap();
    let re_heure = Regex::new(r"<time>(.*)</time>").unwrap();
    let re_lat_lon = Regex::new(r"lat=.(-?\d*\.\d*). lon=.(-?\d*\.\d*)").unwrap();
    let mut min_lat = 10_000.0;
    let mut min_lon = 10_000.0;
    let mut max_lat = -10_000.0;
    let mut max_lon = -10_000.0;
    for piste in re_track.captures_iter(&pistes) {
        let cap2 = re_points.captures(&piste[1]).unwrap();
        resultat.push_str(&cap2[1]);
        let points = &cap2[2];
        let mut heure1 = 0;
        let mut heure2 = 0;
        let mut points_iter = re_point.captures_iter(&points);
        let mut last_point = "".to_string();
        loop {
            match points_iter.next() {
                Some(point) => {
                    assert!(re_lat_lon.is_match(&point[1]));
                    let lat_lon = re_lat_lon.captures(&point[1]).expect("erreur ici");
                    let lat= lat_lon[1].parse::<f64>().unwrap();
                    let lon= lat_lon[2].parse::<f64>().unwrap();
                    if lat > max_lat {max_lat = lat} else if lat < min_lat {min_lat = lat};
                    if lon > max_lon {max_lon = lon} else if lon < min_lon {min_lon = lon};
                    heure2 = DateTime::parse_from_rfc3339(&re_heure.captures(&point[1]).unwrap()[1]).unwrap().timestamp();
                    match heure1 {
                        0 => {
                            resultat.push_str(&point[1]);
                            heure1 = heure2;
                        },
                        _ => {
                            let ecart = heure2 - heure1;
                            if  ecart > 60 {
                                resultat.push_str(&point[1]);
                                last_point = "".to_string();
                                heure1 = heure2;
                            } else {
                                last_point = String::from(&point[1]);
                            }
                        }
                    }
                },
                _ => {
                    if last_point != String::from("") {
                        resultat.push_str(last_point.as_str());
                    }
                    break
                },
            }
        };
        resultat.push_str(&cap2[3]);
    }
    resultat.push_str(&cap1[3]);
    let re_bounds = Regex::new(r"(?s)<bounds .*?/>").unwrap();
    if re_bounds.is_match(&resultat) {
        let bounds = format!("<bounds maxlat=\"{}÷\" maxlon=\"{}\" minlat=\"{}\" minlon=\"{}\"/>", max_lat, max_lon, min_lat, min_lon);
        resultat = String::from(re_bounds.replace(&resultat, bounds.as_str()));
    };
    resultat

}

fn traite(nom: String) -> String {
    let r = lit_trace(&nom);
    let points = r.2;
    let mut resultat = Resultat { heure_debut: r.0 , heure_fin: r.1,
        lon_depart: points.first().unwrap().first().unwrap().lon,
        lat_depart: points.first().unwrap().first().unwrap().lat,
        lon_arrivee: points.last().unwrap().last().unwrap().lon,
        lat_arrivee: points.last().unwrap().last().unwrap().lat,
        altitude_mini: 0.0, altitude_maxi: 0.0, cumul_montee: 0.0, cumul_descente: 0.0,
        distance: 0.0, lat_min: r.3, lat_max: r.4, lon_min: r.5, lon_max: r.6,
        profil: vec![]};

    let r = traite_altitudes(&points);
    resultat.altitude_mini = r.0;
    resultat.altitude_maxi = r.1;
    resultat.cumul_montee = r.2;
    resultat.cumul_descente = r.3;
    let altitudes_lissees = r.4;
    let distances_cumulees = traite_distances(points);
    resultat.distance = *distances_cumulees.last().unwrap().last().unwrap();
    resultat.profil = construit_profil(&altitudes_lissees, resultat.altitude_mini, resultat.altitude_maxi,
                                       distances_cumulees, resultat.distance);
    serde_json::to_string(&resultat).unwrap()
}

ruby! {
    class GpxTraite {
        def traite_une_trace(nom: String) -> String {
            traite(nom)
        }
        def traite_liste_fichiers(nom: String) -> String {
            let p: ListeGpx = serde_json::from_str(&nom).unwrap();
            let mut resultat = fs::read_to_string(&p.fichiers[0]).unwrap();
            let re_track = Regex::new(r"(?s).*?(<trk>.*</gpx>)").unwrap();
            for i in 1..p.fichiers.len() {
                let contents = fs::read_to_string(&p.fichiers[i]).unwrap();
                let cap = re_track.captures(&contents).unwrap();
                resultat = resultat.replace("</gpx>", &cap[1]);
            }
            let resultat_simplifie = simplifie_resultat(resultat);
            fs::write(&p.resultat, resultat_simplifie).unwrap();
            traite(p.resultat)
        }
    }
}