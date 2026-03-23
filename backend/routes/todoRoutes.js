const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const todoController = require('../controllers/todoController');

router.use(auth);

router.post('/', todoController.createTodo);
router.get('/user/:id', todoController.getUserTodos);
router.get('/today', todoController.getTodayTodos);
router.get('/upcoming', todoController.getUpcomingTodos);
router.get('/:id', todoController.getTodo);
router.put('/:id', todoController.updateTodo);
router.delete('/:id', todoController.deleteTodo);

module.exports = router;
