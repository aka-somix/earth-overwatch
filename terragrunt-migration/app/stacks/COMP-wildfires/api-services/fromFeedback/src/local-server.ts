import app from "./app"; // Adjust the path to where your app is defined

const port = 3000; // You can choose any port

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
