package domain
type Department struct { ID int `json:"id"`; Name string `json:"name"` }
type DepartmentRepository interface { ListAll() ([]Department, error) }
