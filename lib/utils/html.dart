String html = """

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>SAURAYA WEBSITE BUILDER</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Audiowide&family=Comfortaa:wght@300..700&family=Exo+2:ital,wght@0,100..900;1,100..900&family=Mukta:wght@200;300;400;500;600;700;800&family=Orbitron:wght@400..900&family=Quicksand:wght@300..700&family=Righteous&family=Roboto+Flex:opsz,wght@8..144,100..1000&family=Roboto+Mono:ital,wght@0,100..700;1,100..700&family=Rubik:ital,wght@0,300..900;1,300..900&display=swap');
    </style>
  <style>
    /* Reset de base */
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
    background-image: url(https://sauraya.com/blur.png);
      min-height: 100vh;
      background-color: #0D0D0D;
      font-family: 'Lucida Sans', 'Lucida Sans Regular', 'Lucida Grande', 
                   'Lucida Sans Unicode', Geneva, Verdana, sans-serif;
      color: #FFFFFF;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 2rem;
    }

    header {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-bottom: 2rem;
      text-align: center;
    }

    header img {
      width: 150px;
      margin-bottom: 1rem;
    }

    .welcome-text {
      font-size: 1.3em;
      font-family: "Audiowide", serif;

    }

    .welcome-text span {
      color: orange;
      text-transform: uppercase;
      font-weight: bold;
      font-family: "Audiowide", serif;

    }

    .instructions {
      max-width: 800px;
      text-align: left;
      border-radius: 8px;
      padding: 1.5rem;
      margin-top: auto; /* Permet de pousser la section en bas si l'écran est grand */
      line-height: 1.6;
    }

    .instructions h2 {
    

      margin-bottom: 1rem;
      color: orange;
      padding: 7px;
      border-left: 1px solid orange;
      font-size: 1.5em;
      font-family: "Audiowide", serif;

    }

    .instructions p {
        font-family: "Rubik", serif;

      font-weight: 100;
      font-size: 0.9em;
      margin-bottom: 1rem;
    }
  </style>
</head>
<body>
  <header>
    <img src="https://sauraya.com/tr.png" alt="Sauraya" />
    <div class="welcome-text">
      Welcome to <span>Sauraya Builder</span>
    </div>
  </header>

  <section class="instructions">
    <h2>How to Get Started</h2>
    <p>
      This space is intended to create single web pages for simple uses, such as a blog home page.
      The site is created by AI and can be adjusted with instructions.
    </p>
    <p>
      To start, simply explain to the AI what you want, then click on the "Send" button to send
      your message. This page will then change, and a new page containing your details
      will appear.
    </p>
    <p>
      You can find your projects on the left in the sidebar and navigate between the different projects. 
      Let’s go!
    </p>
  </section>
</body>
</html>

""";
String loaderHtml = """<!DOCTYPE html>
<html style="height: 100%;" lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Loader</title>
 
  <style>
    .loader {
    color: #fff;
    font-family: Consolas, Menlo, Monaco, monospace;
    font-weight: bold;
    font-size: 78px;
    opacity: 0.8;
  }
  .loader:before {
    content: "{";
    display: inline-block;
    animation: pulse 0.4s alternate infinite ease-in-out;
  }
  .loader:after {
    content: "}";
    display: inline-block;
    animation: pulse 0.4s 0.3s alternate infinite ease-in-out;
  }

  @keyframes pulse {
    to {
      transform: scale(0.8);
      opacity: 0.5;
    }
  }
      
  </style>
</head>
<body style="display: grid; place-content: center; background-color: #0D0D0D; height: 100%;">
  
  <span class="loader">

  </span>
</body>
</html> """;

String codeError = """
<!DOCTYPE html>
<html lang="en" style="height: 100%;">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Error Page</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      font-family: Arial, sans-serif;
    }

    body {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100%;
      background-color: #0D0D0D;
      color: #FFFFFF;
      text-align: center;
    }

    .error-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
    }

    .icon {
      width: 64px;
      height: 64px;
      stroke: #FF5252;
      animation: pulse 1s infinite alternate;
    }

    h1 {
      font-size: 24px;
      font-weight: bold;
    }

    p {
      font-size: 16px;
      opacity: 0.8;
    }

    .loader {
      font-size: 32px;
      font-weight: bold;
      display: flex;
      gap: 4px;
      align-items: center;
      color: #FF5252;
    }

    .loader::before,
    .loader::after {
      content: "{";
      display: inline-block;
      animation: pulse 0.5s alternate infinite ease-in-out;
    }
    .loader::after {
      content: "}";
      animation-delay: 0.3s;
    }


    
  </style>
</head>
<body>
  <div class="error-container">
    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="10"></circle>
      <line x1="8" y1="15" x2="16" y2="15"></line>
      <line x1="9" y1="9" x2="9.01" y2="9"></line>
      <line x1="15" y1="9" x2="15.01" y2="9"></line>
    </svg>
    <h1>Something went wrong</h1>
    <p>Try to copy this code and <br/> start a new conversation.</p>
  </div>
</body>
</html>

""";
