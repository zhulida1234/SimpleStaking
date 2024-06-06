const express = require('express');
const path = require('path');
const app = express();

// 设置静态文件目录
app.use(express.static(path.join(__dirname, 'first')));
app.use('/artifacts', express.static(path.join(__dirname, 'artifacts')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'first', 'index.html'));
});

const port = 3000;
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});