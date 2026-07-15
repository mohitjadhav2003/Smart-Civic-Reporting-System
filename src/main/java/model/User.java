package model;

public class User {

    private int userId;

    private String name;

    private String email;

    private String password;

    private String mobile;

    private String role;

    private String department;

    private String profileImage;

    /* =========================================================
       DEFAULT CONSTRUCTOR
    ========================================================= */

    public User() {
    }

    /* =========================================================
       REGISTRATION CONSTRUCTOR
    ========================================================= */

    public User(
            String name,
            String email,
            String password,
            String mobile) {

        this.name = name;

        this.email = email;

        this.password = password;

        this.mobile = mobile;

        this.role = "Citizen";
    }

    /* =========================================================
       FULL CONSTRUCTOR
    ========================================================= */

    public User(
            int userId,
            String name,
            String email,
            String password,
            String mobile,
            String role,
            String department,
            String profileImage) {

        this.userId = userId;

        this.name = name;

        this.email = email;

        this.password = password;

        this.mobile = mobile;

        this.role = role;

        this.department = department;

        this.profileImage = profileImage;
    }

    /* =========================================================
       USER ID
    ========================================================= */

    public int getUserId() {

        return userId;
    }

    public void setUserId(int userId) {

        this.userId = userId;
    }

    /* =========================================================
       ID ALIAS
    ========================================================= */

    public int getId() {

        return userId;
    }

    public void setId(int userId) {

        this.userId = userId;
    }

    /* =========================================================
       NAME
    ========================================================= */

    public String getName() {

        return name;
    }

    public void setName(String name) {

        this.name = name;
    }

    /* =========================================================
       EMAIL
    ========================================================= */

    public String getEmail() {

        return email;
    }

    public void setEmail(String email) {

        this.email = email;
    }

    /* =========================================================
       PASSWORD
    ========================================================= */

    public String getPassword() {

        return password;
    }

    public void setPassword(String password) {

        this.password = password;
    }

    /* =========================================================
       MOBILE
    ========================================================= */

    public String getMobile() {

        return mobile;
    }

    public void setMobile(String mobile) {

        this.mobile = mobile;
    }

    /* =========================================================
       ROLE
    ========================================================= */

    public String getRole() {

        return role;
    }

    public void setRole(String role) {

        this.role = role;
    }

    /* =========================================================
       DEPARTMENT
    ========================================================= */

    public String getDepartment() {

        return department;
    }

    public void setDepartment(String department) {

        this.department = department;
    }

    /* =========================================================
       PROFILE IMAGE
    ========================================================= */

    public String getProfileImage() {

        return profileImage;
    }

    public void setProfileImage(String profileImage) {

        this.profileImage = profileImage;
    }
}