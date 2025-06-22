/**
 * JS Login :
 *  - Valide le formulaire côte client
 *  - Appelle /api/login-json
 *  - Stocke le JWT dans localStorage (cle : jwt_token)
 *  - Redirige vers /user_dashboard
 */

document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("loginForm");
  const err = document.getElementById("errorMessage");
  const ok  = document.getElementById("successMessage");

  form.addEventListener("submit", async (evt) => {
    evt.preventDefault();
    err.textContent = ""; ok.textContent = "";

    const email    = document.getElementById("email").value.trim();
    const password = document.getElementById("password").value;

    try {
      const resp = await fetch("/api/login-json", {
        method : "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body   : new URLSearchParams({ email, password })
      });

      const data = await resp.json();

      if (resp.ok) {
        if (data.token) {
          localStorage.setItem("jwt_token", data.token);
        }
        ok.textContent = "Connexion reussie !";
        setTimeout(() => window.location.href = "/user_dashboard", 800);
      } else {
        err.textContent = data.error || "Erreur de connexion.";
      }
    } catch (e) {
      console.error(e);
      err.textContent = "Erreur reseau.";
    }
  });
});
