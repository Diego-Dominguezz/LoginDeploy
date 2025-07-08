// Funciones existentes en funciones.js

// Selección de elementos de la página
const productos = document.getElementById("productos");
const orden = document.getElementById("orden");
let intervaloOfertas;
let ofertasIndex = 0;

// Nuevo array para las imágenes de la galería
const galeriaImagenes = [
    "../img/smile.png",
    "../img/hables.png",
    "../img/venom.png"
];

// Array de películas
const peliculas = [
    { titulo: "Smile", img: "../img/smile.png" },
    { titulo: "Hables", img: "../img/hables.png" },
    { titulo: "Venom", img: "../img/venom.png" }
];

let intervaloPeliculas; // Intervalo para películas
let peliculasIndex = 0; // Índice para la película actual

// Función para mostrar una oferta después de 15 segundos usando Promises y async/await
async function mostrarOfertas() {
    clearInterval(intervaloOfertas); // Detener cualquier intervalo activo previo
    intervaloOfertas = setInterval(async () => {
        const oferta = await obtenerOferta();
        mostrarImagen(oferta);
    }, 1000); // Cambiar cada segundo (ajustable)
}

// Simulación de obtener oferta después de cierto tiempo con setTimeout y Promise
function obtenerOferta() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve(ofertas[ofertasIndex % ofertas.length]);
            ofertasIndex++;
        }, 1000); // espera de 1 segundo antes de obtener la oferta
    });
}

// Función para mostrar la imagen de oferta en el cuadro de departamentos
function mostrarImagen(url) {
    let imagen = document.getElementById("imagen-oferta");
    if (!imagen) {
        imagen = document.createElement("img");
        imagen.id = "imagen-oferta";
        orden.appendChild(imagen);
    }
    imagen.src = url;
}

// Cdigo para manejar películas

// Función para mostrar películas en un intervalo
async function mostrarPeliculas() {
    clearInterval(intervaloPeliculas); // Detiene cualquier intervalo previo
    intervaloPeliculas = setInterval(async () => {
        const pelicula = await obtenerPelicula();
        mostrarPelicula(pelicula);
    }, 2000); // Cambia cada 2 segundos
}

// Simulación de obtener película
function obtenerPelicula() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve(peliculas[peliculasIndex % peliculas.length]);
            peliculasIndex++;
        }, 500); // Simula un pequeño retardo
    });
}

// Función para mostrar una película
function mostrarPelicula(pelicula) {
    const contenedorPeliculas = document.getElementById("contenedor-peliculas");
    contenedorPeliculas.innerHTML = ""; // Limpia contenido previo

    // Crear elementos para imagen y título
    const img = document.createElement("img");
    img.src = pelicula.img;
    img.alt = pelicula.titulo;
    img.style.width = "150px"; // Ajusta el tamaño según sea necesario

    const titulo = document.createElement("p");
    titulo.textContent = pelicula.titulo;

    // Añadir elementos al contenedor
    contenedorPeliculas.appendChild(img);
    contenedorPeliculas.appendChild(titulo);
}

// Función para mostrar galería
function mostrarGaleria() {
    const galeria = document.getElementById("galeria");
    galeria.innerHTML = ""; // Limpia cualquier contenido previo

    galeriaImagenes.forEach((url) => {
        const img = document.createElement("img");
        img.src = url;
        img.alt = "Imagen de galería";
        img.style.width = "150px"; // Ajusta el tamaño según sea necesario
        img.style.height = "auto"; // Mantiene la proporción
        galeria.appendChild(img);
    });
}
