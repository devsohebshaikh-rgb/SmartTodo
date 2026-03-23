const todoService = require('../services/todoService');

const createTodo = async (req, res) => {
  try {
    const userId = req.user.id;
    const { locationId, taskTitle, taskDescription, reminderRadius } = req.body;

    if (!locationId || !taskTitle) {
      return res.status(400).json({ success: false, message: 'Location ID and task title are required' });
    }

    const todoId = await todoService.createTodo(userId, locationId, taskTitle, taskDescription, reminderRadius);
    const todo = await todoService.getTodoById(todoId);

    return res.status(201).json({ success: true, data: todo });
  } catch (error) {
    console.error('Create todo error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getUserTodos = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status } = req.query;

    let todos;
    if (status) {
      todos = await todoService.getTodosByStatus(userId, status);
    } else {
      todos = await todoService.getTodosByUserId(userId);
    }

    return res.status(200).json({ success: true, data: todos });
  } catch (error) {
    console.error('Get user todos error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getTodo = async (req, res) => {
  try {
    const { id } = req.params;
    const todo = await todoService.getTodoById(id);

    if (!todo) {
      return res.status(404).json({ success: false, message: 'Todo not found' });
    }

    return res.status(200).json({ success: true, data: todo });
  } catch (error) {
    console.error('Get todo error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const updateTodo = async (req, res) => {
  try {
    const { id } = req.params;
    const fields = req.body;

    const affectedRows = await todoService.updateTodo(id, fields);

    if (affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Todo not found or no fields to update' });
    }

    const updatedTodo = await todoService.getTodoById(id);
    return res.status(200).json({ success: true, data: updatedTodo });
  } catch (error) {
    console.error('Update todo error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const deleteTodo = async (req, res) => {
  try {
    const { id } = req.params;
    const affectedRows = await todoService.deleteTodo(id);

    if (affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Todo not found' });
    }

    return res.status(200).json({ success: true, message: 'Todo deleted successfully' });
  } catch (error) {
    console.error('Delete todo error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getTodayTodos = async (req, res) => {
  try {
    const userId = req.user.id;
    const todos = await todoService.getTodosForToday(userId);

    return res.status(200).json({ success: true, data: todos });
  } catch (error) {
    console.error('Get today todos error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getUpcomingTodos = async (req, res) => {
  try {
    const userId = req.user.id;
    const todos = await todoService.getUpcomingTodos(userId);

    return res.status(200).json({ success: true, data: todos });
  } catch (error) {
    console.error('Get upcoming todos error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

module.exports = {
  createTodo,
  getUserTodos,
  getTodo,
  updateTodo,
  deleteTodo,
  getTodayTodos,
  getUpcomingTodos,
};
